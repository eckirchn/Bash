const axios = require('axios');
var express = require('express');
var router = express.Router();
var { setKeyValue, getValueByKey, getAllVariables, deleteVariable, dropVariablesTable } = require('../services/localVariablesService');
const { init } = require('../services/switchBotService');
const CryptoJS = require('crypto-js');
const { v4: uuidv4 } = require('uuid');
const { table } = require('../config/localDB');
const crypto = require('crypto');

var switchBotAPI;

const SWITCHBOT_CLIENT_ID = '5nnwmhmsa9xxskm14hd85lm9bm';
const SWITCHBOT_CLIENT_SECRET = 'vzxjw7rvmduka4rlysdcv0bfke70icql33ol1pvr';

function decodeJwtPayload(token) {
    try {
        const part = String(token).split('.')[1];
        if (!part) return null;
        const b64 = part.replace(/-/g, '+').replace(/_/g, '/');
        const pad = b64.length % 4 === 0 ? '' : '='.repeat(4 - (b64.length % 4));
        return JSON.parse(Buffer.from(b64 + pad, 'base64').toString('utf8'));
    } catch (err) {
        return null;
    }
}

function userIdFromToken(token) {
    const payload = decodeJwtPayload(token);
    if (!payload) return null;
    return payload.userID || payload.userId || null;
}

function switchbotErrorMessage(data, fallback) {
    if (data && typeof data.message === 'string' && data.message) return data.message;
    if (data && data.statusCode) return 'SwitchBot status ' + data.statusCode;
    return fallback;
}

function logSwitchbot(step, data) {
    const body = data && data.body;
    console.log(
        step,
        'statusCode:', data && data.statusCode,
        'mfa:', !!(body && body.mfa_enabled),
        'hasToken:', !!(body && typeof body.access_token === 'string')
    );
}

async function retryUntilSuccess(fn, maxRetries = 5, delay = 1000) {
    let attempt = 0;
    while (attempt < maxRetries) {
        try {
            return await fn();
        } catch (err) {
            attempt++;
            if (attempt >= maxRetries) throw err;
            await new Promise(resolve => setTimeout(resolve, delay));
        }
    }
}

function rememberSession(accessToken, refreshToken) {
    if (typeof accessToken !== 'string' || !accessToken) {
        throw new Error('Login response missing access_token');
    }
    setKeyValue('TOKEN', accessToken);
    if (typeof refreshToken === 'string' && refreshToken) {
        setKeyValue('refreshToken', refreshToken);
    }
    const userID = userIdFromToken(accessToken);
    if (userID) setKeyValue('userID', String(userID));
}

async function finishLogin(accessToken, refreshToken) {
    rememberSession(accessToken, refreshToken);
    deleteVariable('mfaToken');
    await retryUntilSuccess(() => axios.post('http://localhost:8089/switchbot/userinfo'));
    await retryUntilSuccess(() => axios.post('http://localhost:8089/switchbot/endpoint'));
    await retryUntilSuccess(() => axios.post('http://localhost:8089/switchbot/getdevice'));
    await retryUntilSuccess(() => axios.post('http://localhost:8089/switchbot/token'));
    switchBotAPI = await init();
}

async function sendMfaEmail(mfaToken) {
    const response = await axios.post(
        'https://account.api.switchbot.net/account/api/v2/verification/code/send',
        {
            clientId: SWITCHBOT_CLIENT_ID,
            method: 'email',
            ops: 'mfa',
            proof: { mfaToken: mfaToken }
        }
    );
    return response.data || {};
}

function newDeviceId() {
    const uuid = uuidv4().replace(/-/g, '');
    return uuid.slice(0, 4) + '-' +
        uuid.slice(4, 8) + '-' +
        uuid.slice(8, 12) + '-' +
        uuid.slice(12, 16);
}


router.get('/geticons', async function (req, res) {
    try {
        let url = "https://prod-switchbot-icons.s3.amazonaws.com/wo_device_icon.json";
        const response = await axios.get(url);
        res.status(200).json(response.data);
    } catch (error) {
        console.error('Error fetching icons:', error);
        res.status(500).json({ error: 'Failed to fetch icons' });
    }
});

router.post('/login', async function (req, res) {
    try {
        const { email, encryptedPassword, verifyCode, resend } = req.body || {};

        if (resend) {
            const mfaToken = getValueByKey('mfaToken');
            if (!mfaToken) {
                return res.status(401).json({ error: 'Two-step session expired. Sign in again.', mfaExpired: true });
            }
            const sent = await sendMfaEmail(mfaToken);
            logSwitchbot('MFA resend', sent);
            if (Number(sent.statusCode) === 2007) {
                deleteVariable('mfaToken');
                return res.status(401).json({ error: 'Two-step session expired. Sign in again.', mfaExpired: true });
            }
            if (Number(sent.statusCode) !== 100) {
                return res.status(200).json({
                    mfaRequired: true,
                    error: switchbotErrorMessage(sent, 'Could not resend the email code.')
                });
            }
            return res.status(200).json({ mfaRequired: true });
        }

        if (verifyCode) {
            const mfaToken = getValueByKey('mfaToken');
            const deviceId = getValueByKey('deviceId');
            const deviceName = getValueByKey('deviceName');
            const model = getValueByKey('model');
            if (!mfaToken || !deviceId) {
                return res.status(401).json({ error: 'Two-step session expired. Sign in again.', mfaExpired: true });
            }
            const verifyResp = await axios.post(
                'https://account.api.switchbot.net/account/api/v1/user/mfa/verify',
                {
                    clientId: SWITCHBOT_CLIENT_ID,
                    auth: { method: 'email', credential: String(verifyCode).trim() },
                    mfaToken: mfaToken,
                    deviceInfo: {
                        deviceId: deviceId,
                        deviceName: deviceName,
                        model: model
                    }
                }
            );
            const vdata = verifyResp.data || {};
            const vbody = vdata.body || {};
            logSwitchbot('MFA verify', vdata);
            if (Number(vdata.statusCode) === 2007) {
                deleteVariable('mfaToken');
                return res.status(401).json({ error: 'That code expired. Sign in again.', mfaExpired: true });
            }
            if (Number(vdata.statusCode) !== 100 || typeof vbody.access_token !== 'string') {
                return res.status(401).json({ error: switchbotErrorMessage(vdata, 'That code was not accepted.') });
            }
            await finishLogin(vbody.access_token, vbody.refresh_token);
            return res.status(200).json({ loggedIn: true });
        }

        if (!email || !encryptedPassword) {
            return res.status(400).json({ error: 'Email and password are required' });
        }

        let decryptedPassword;
        try {
            const bytes = CryptoJS.AES.decrypt(encryptedPassword, 'github.com/dbghelp');
            decryptedPassword = bytes.toString(CryptoJS.enc.Utf8);
        } catch (decryptErr) {
            return res.status(400).json({ error: 'Could not read the password' });
        }
        if (!decryptedPassword) {
            return res.status(400).json({ error: 'Could not read the password' });
        }

        const deviceId = newDeviceId();
        const deviceName = 'Galaxy S20 Ultra 5G';
        const model = 'SM-G988B/DS';
        const appVersion = '9.12';

        const response = await axios.post(
            'https://account.api.switchbot.net/account/api/v2/user/login',
            {
                clientId: SWITCHBOT_CLIENT_ID,
                deviceInfo: {
                    appVersion: appVersion,
                    deviceId: deviceId,
                    deviceName: deviceName,
                    model: model
                },
                grantType: 'password',
                password: decryptedPassword,
                username: email,
                verifyCode: ''
            }
        );

        const data = response.data || {};
        const body = data.body || {};
        logSwitchbot('Login', data);

        if (Number(data.statusCode) !== 100) {
            return res.status(401).json({ error: switchbotErrorMessage(data, 'SwitchBot rejected the login') });
        }

        setKeyValue('appVersion', appVersion);
        setKeyValue('deviceId', deviceId);
        setKeyValue('deviceName', deviceName);
        setKeyValue('model', model);
        setKeyValue('email', email);
        setKeyValue('encryptedPassword', encryptedPassword);

        if (body.mfa_enabled && body.mfa_token && typeof body.access_token !== 'string') {
            setKeyValue('mfaToken', body.mfa_token);
            setKeyValue('mfaEnabled', 'true');
            const sent = await sendMfaEmail(body.mfa_token);
            logSwitchbot('MFA code send', sent);
            if (Number(sent.statusCode) === 2007) {
                deleteVariable('mfaToken');
                return res.status(401).json({ error: 'Two-step session expired. Sign in again.', mfaExpired: true });
            }
            if (Number(sent.statusCode) !== 100) {
                return res.status(200).json({
                    mfaRequired: true,
                    error: switchbotErrorMessage(sent, 'Could not send the email code. Use resend.')
                });
            }
            return res.status(200).json({ mfaRequired: true });
        }

        if (typeof body.access_token !== 'string') {
            return res.status(401).json({ error: switchbotErrorMessage(data, 'SwitchBot did not return a login token') });
        }

        deleteVariable('mfaEnabled');
        await finishLogin(body.access_token, body.refresh_token);
        return res.status(200).json({ loggedIn: true });
    } catch (error) {
        const remote = error.response && error.response.data;
        console.error(
            'Error logging in:',
            error.message,
            'statusCode:', remote && remote.statusCode,
            'message:', remote && remote.message
        );
        if (error.response) {
            return res.status(401).json({ error: switchbotErrorMessage(remote, 'Error logging in') });
        }
        return res.status(500).json({ error: 'Error logging in' });
    }
});

router.post('/userinfo', async function (req, res) {
    try {
        const url = "https://account.api.switchbot.net/account/api/v1/user/userinfo";
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }
        const response = await axios.post(url, {}, { headers: headers });
        res.status(200).json(response.data);
        const botRegion = response.data && response.data.body && response.data.body.botRegion;
        if (botRegion) {
            setKeyValue('botRegion', botRegion);
        }
    } catch (error) {
        console.error('Error getting user info', error);
        res.status(500).json({ error: 'Error getting user info' });
    }
});

router.post('/checkLogin', async function (req, res) {
    try {
        if (!getValueByKey('TOKEN')) {
            return res.status(401).json({ error: 'Unauthorized: No token found', 'Logged in': false });
        }

        if (!getValueByKey('email')) {
            return res.status(401).json({ error: 'Unauthorized: No email found', 'Logged in': false });
        }

        let userInfoResponse;
        try {
            userInfoResponse = await axios.post('http://localhost:8089/switchbot/userinfo');
        } catch (err) {
            try {
                if (getValueByKey('refreshToken') && getValueByKey('userID') && getValueByKey('deviceId')) {
                    await axios.post('http://localhost:8089/switchbot/refreshToken');
                } else if (getValueByKey('mfaEnabled') === 'true') {
                    return res.status(401).json({ error: 'Two-step sign-in required', 'Logged in': false });
                } else if (getValueByKey('encryptedPassword')) {
                    const loginResp = await axios.post('http://localhost:8089/switchbot/login', {
                        email: getValueByKey('email'),
                        encryptedPassword: getValueByKey('encryptedPassword')
                    });
                    if (loginResp.data && loginResp.data.mfaRequired) {
                        return res.status(401).json({ error: 'Two-step sign-in required', 'Logged in': false });
                    }
                } else {
                    return res.status(401).json({ error: 'Re-login failed', 'Logged in': false });
                }
                userInfoResponse = await axios.post('http://localhost:8089/switchbot/userinfo');
            } catch (loginErr) {
                return res.status(401).json({ error: 'Re-login failed', 'Logged in': false });
            }
        }

        if (!userInfoResponse || userInfoResponse.status !== 200) {
            return res.status(401).json({ error: 'User info fetch failed', 'Logged in': false });
        }

        res.status(200).json({ 'Logged in': true });
    } catch (error) {
        console.error('Not logged in', error);
        res.status(500).json({ error: 'Internal error', 'Logged in': false });
    }
});


router.post('/endpoint', async function (req, res) {
    try {
        const url = "https://account.api.switchbot.net/admin/admin/api/v1/botregion/endpoint";
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }
        const body = {
            "botRegion": getValueByKey('botRegion')
        }
        const response = await axios.post(url, body, { headers: headers });

        const wonderlabsItem = response.data.data.find(item => item.name === "wonderlabs");

        setKeyValue('wonderlabsAPI', wonderlabsItem.host);
        res.status(200).json(response.data.data);
    } catch (error) {
        console.error('Error on endpoint', error);
        res.status(500).json({ error: 'Error on endpoint' });
    }
});


//get groupID
router.post('/getdevice', async function (req, res) {
    try {
        const url = `${getValueByKey('wonderlabsAPI')}/wonder/device/v3/getdevice`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }
        const body = {
            "required_type": "All"
        }
        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data.body.Items);
        setKeyValue('groupID', response.data.body.Items[0].groupID);
    } catch (error) {
        console.error('Error on getdevice', error);
        res.status(500).json({ error: 'Error on getdevice' });
    }
});

router.post('/getList', async function (req, res) {
    try {
        const url = `${getValueByKey('wonderlabsAPI')}/scene/v1/scene/getList`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }
        const body = {
            "groupID": getValueByKey('groupID'),
            "sceneType": "automation"
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data.data);
    } catch (error) {
        console.error('Error on getList', error);
        res.status(500).json({ error: 'Error on getList' });
    }
});

router.post('/getall', async function (req, res) {
    try {
        //await axios.post('http://localhost:8089/switchbot/getdevice');
        const url = `${getValueByKey('wonderlabsAPI')}/homepage/v1/device/getall`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }
        const body = {
            "groupID": getValueByKey('groupID'),
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data.data);
    } catch (error) {
        console.error('Error on getall', error);
        res.status(500).json({ error: 'Error on getall' });
    }
});


router.post('/dataDetail', async function (req, res) {
    try {
        //await axios.post('http://localhost:8089/switchbot/getdevice');
        const url = `${getValueByKey('wonderlabsAPI')}/devicedata/v1/data/detail`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }
        const { deviceId } = req.body;
        const currentTime = Date.now();
        const body = {
            "dataMetricsTypes": [
                "temperature",
                "humidity"
            ],
            "deviceID": deviceId,
            "deviceType": "WoMeter",
            "end": currentTime,
            "start": currentTime
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data.data);
    } catch (error) {
        console.error('Error on dataDetail', error);
        res.status(500).json({ error: 'Error on dataDetail' });
    }
});


router.post('/remoteinfo', async function (req, res) {
    try {
        const url = `${getValueByKey('wonderlabsAPI')}/homepage/v1/device/remoteinfo`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }

        const body = {
            "remoteID": req.body.remoteID,
            "ownerUserID": req.body.userID
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data.data);
    } catch (error) {
        console.error('Error on remoteinfo', error);
        res.status(500).json({ error: 'Error on remoteinfo' });
    }
});

router.post('/sceneChangeEnable', async function (req, res) {
    try {
        const url = `${getValueByKey('wonderlabsAPI')}/scene/v1/scene/changeEnable`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }

        const body = {
            "enable": req.body.enable,
            "isOld": false,
            "sceneID": req.body.sceneID
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data.data);
    } catch (error) {
        console.error('Error on sceneChangeEnable', error);
        res.status(500).json({ error: 'Error on sceneChangeEnable' });
    }
});

router.post('/token', async function (req, res) {
    try {
        const url = `${getValueByKey('wonderlabsAPI')}/wonder/openapi/openUser/token`;
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }

        const body = {
            "operation": "get",
            "version": 2
        }

        const response = await axios.post(url, body, { headers: headers });

        const encryptedAppToken = response.data.body.token;
        const encryptedSecretKey = response.data.body.secretKey;
        
        function decryptToHex(encryptedHex) {
            try {
                const key = 'lrQ0OTvwp9RTsXxk';
                const iv = '4mdN27rI3bk2LzWa'; 
                const encryptedBuffer = Buffer.from(encryptedHex, 'hex');
                const keyBuffer = Buffer.from(key, 'utf8');
                const ivBuffer = Buffer.from(iv, 'utf8');
        
                const decipher = crypto.createDecipheriv('aes-128-cbc', keyBuffer, ivBuffer);
                const decryptedBuffer = Buffer.concat([
                    decipher.update(encryptedBuffer),
                    decipher.final()
                ]);
        
                return decryptedBuffer.toString('hex');
            } catch (err) {
                console.error('Decryption failed:', err.message);
                return '';
            }
        }

        const appToken = decryptToHex(encryptedAppToken);
        const secretKey = decryptToHex(encryptedSecretKey);

        setKeyValue('appToken', appToken);
        setKeyValue('secretKey', secretKey);

        res.status(200).json({'token' : appToken, 'secretKey': secretKey});
    } catch (error) {
        console.error('Error on token', error);
        res.status(500).json({ error: 'Error on token' });
    }
});


router.post('/controlDevice', async function (req, res) {
    try {
        const { deviceId, command, parameter } = req.body;

        const response = await switchBotAPI.controlDevice(deviceId, command, parameter, 'customize');

        //console.log(response);

        res.status(200).json(response);
    } catch (error) {
        console.error('Error on controlDevice', error);
        res.status(500).json({ error: 'Error on controlDevice' });
    }
});

router.post('/getDeviceStatus', async function (req, res) {
    try {
        const { deviceId } = req.body;

        const status = await switchBotAPI.getDeviceStatus(deviceId)

        //console.log(status);

        res.status(200).json(status);
    } catch (error) {
        console.error('Error on getDeviceStatus', error);
        res.status(500).json({ error: 'Error on getDeviceStatus' });
    }
});

router.post('/sendCode', async function (req, res) {
    try {
        const url = "https://account.api.switchbot.net/account/api/v2/verification/code/send";
        const headers = {
            'authorization': getValueByKey('TOKEN')
        }

        const body = {
            "clientId": "5nnwmhmsa9xxskm14hd85lm9bm",
            "lang": "en",
            "method": "email",
            "ops": "change"
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data);
    } catch (error) {
        console.error('Error on sendCode', error);
        res.status(500).json({ error: 'Error on sendCode' });
    }
});

router.post('/changePassword', async function (req, res) {
    try {
        const url = "https://account.api.switchbot.net/account/api/v3/user/password/change";
        const { newPassword, credential } = req.body;

        const headers = {
            'authorization': getValueByKey('TOKEN')
        }

        const body = {
            "auth": {
                "credential": credential,
                "method": "email"
            },
            "clientId": "5nnwmhmsa9xxskm14hd85lm9bm",
            "deviceInfo": {
                "deviceId": getValueByKey('deviceId'),
                "deviceName": getValueByKey('deviceName'),
                "model": getValueByKey('model')
            },
            "lang": "en",
            "password": newPassword
        }

        const response = await axios.post(url, body, { headers: headers });
        res.status(200).json(response.data);
    } catch (error) {
        console.error('Error on changePassword', error);
        res.status(500).json({ error: 'Error on changePassword' });
    }
});

router.post('/dropTable', async function (req, res) {
    try {
        await dropVariablesTable();
        res.status(200).json({ message: 'Variables table dropped successfully' });
    } catch (error) {
        console.error('Failed to drop Variables table', error);
        res.status(500).json({ error: 'Failed to drop Variables table' });
    }
});

router.post('/refreshToken', async function (req, res) {
    try {
        const storedRefresh = getValueByKey('refreshToken');
        const userID = getValueByKey('userID');
        const deviceId = getValueByKey('deviceId');

        if (storedRefresh && userID && deviceId) {
            const response = await axios.post(
                'https://account.api.switchbot.net/account/api/v1/user/token/refresh',
                {
                    clientId: SWITCHBOT_CLIENT_ID,
                    clientSecret: SWITCHBOT_CLIENT_SECRET,
                    deviceId: deviceId,
                    refreshToken: storedRefresh,
                    userId: userID
                }
            );
            const data = response.data || {};
            const body = data.body || {};
            logSwitchbot('Token refresh', data);
            if (Number(data.statusCode) === 100 && typeof body.access_token === 'string') {
                rememberSession(body.access_token, body.refresh_token || storedRefresh);
                return res.status(200).json({ refreshed: true });
            }
            return res.status(401).json({ error: switchbotErrorMessage(data, 'Session expired. Sign in again.') });
        }

        if (getValueByKey('mfaEnabled') === 'true') {
            return res.status(401).json({ error: 'Session expired. Sign in again.', mfaRequired: true });
        }

        const encryptedPassword = getValueByKey('encryptedPassword');
        const email = getValueByKey('email');
        if (!encryptedPassword || !email) {
            return res.status(401).json({ error: 'Not logged in' });
        }

        let decryptedPassword;
        try {
            const bytes = CryptoJS.AES.decrypt(encryptedPassword, 'github.com/dbghelp');
            decryptedPassword = bytes.toString(CryptoJS.enc.Utf8);
        } catch (decryptErr) {
            return res.status(401).json({ error: 'Stored password could not be read' });
        }
        if (!decryptedPassword) {
            return res.status(401).json({ error: 'Stored password could not be read' });
        }

        const response = await axios.post(
            'https://account.api.switchbot.net/account/api/v2/user/login',
            {
                clientId: SWITCHBOT_CLIENT_ID,
                deviceInfo: {
                    appVersion: getValueByKey('appVersion'),
                    deviceId: getValueByKey('deviceId'),
                    deviceName: getValueByKey('deviceName'),
                    model: getValueByKey('model')
                },
                grantType: 'password',
                password: decryptedPassword,
                username: email,
                verifyCode: ''
            }
        );
        const data = response.data || {};
        const body = data.body || {};
        logSwitchbot('Password refresh', data);
        if (body.mfa_enabled || typeof body.access_token !== 'string') {
            if (body.mfa_token) setKeyValue('mfaToken', body.mfa_token);
            setKeyValue('mfaEnabled', 'true');
            return res.status(401).json({ error: 'Two-step sign-in required', mfaRequired: true });
        }
        rememberSession(body.access_token, body.refresh_token);
        return res.status(200).json({ refreshed: true });
    } catch (error) {
        const remote = error.response && error.response.data;
        console.error(
            'Error on refreshToken:',
            error.message,
            'statusCode:', remote && remote.statusCode,
            'message:', remote && remote.message
        );
        return res.status(401).json({ error: 'Error on refreshToken' });
    }
});


module.exports = router;
