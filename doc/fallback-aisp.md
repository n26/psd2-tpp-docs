# PSD2 Fallback API - AISP access documentation

1. [Access & Identification of TPP](./fallback-aisp.md#access--identification-of-tpp)
    1. [Base URL](./fallback-aisp.md#base-url)
    2. [Characteristics of this solution](./fallback-aisp.md#characteristics-of-this-solution)
2. [User Authentication](./fallback-aisp.md#user-authentication)
    1. [Overview](./fallback-aisp.md#overview)
    2. [Start authentication with username & password](./fallback-aisp.md#start-authentication-with-username--password)
    3. [Continue authentication with Two-Step Certification (OOB) - Recommended](./fallback-aisp.md#continue-authentication-with-two-step-certification-oob---recommended)
    4. [Continue authentication with Two-Step SMS (OTP) - Not Recommended](./fallback-aisp.md#continue-authentication-with-two-step-sms-otp---not-recommended)
    5. [Get access and refresh tokens](./fallback-aisp.md#get-access-and-refresh-tokens)
    6. [Get new access & refresh token from valid refresh token](./fallback-aisp.md#get-new-access--refresh-token-from-valid-refresh-token)
3. [Account & User information](./fallback-aisp.md#account--user-information)
    1. [Overview](./fallback-aisp.md#overview-1)
    2. [Get accounts information](./fallback-aisp.md#get-accounts-information)
    3. [Get a single account information](./fallback-aisp.md#get-a-single-account-information)
4. [Account Transactions](./fallback-aisp.md#account-transactions)
    1. [Overview](./fallback-aisp.md#overview-2)
    2. [Get Account Transactions](./fallback-aisp.md#get-account-transactions)
    3. [Get Account Transaction Details](./fallback-aisp.md#get-account-transaction-details)
    

## Access & Identification of TPP

### Base URL

`https://aisp.tech26.de`

#### On-boarding of new TPPs

1. A TPP shall connect to the N26 PSD2 API by using an eIDAS valid certificate (QWAC) issued
2. N26 shall check the QWAC certificate in an automated way and allow the TPP to identify themselves  with the subsequent API calls
3. As the result of the steps above, the TPP should be able to continue using the API without manual involvement from the N26 side
> :information_source: Certificates can be renewed by making an API call **using the new certificate**, which will then
> be onboarded automatically.

### Characteristics of this solution

#### Identification of TPP through QWAC

Please use your QWAC certificate when calling for any request on `aisp.tech26.de`.

#### Data which needs to be stored & provided

Third parties will need to store following data in order to access API:

* refresh token with the date it will expire
* device token

Additionally, Third parties are obliged to send following data in every request to our API:

* device token : `device-token: {{device_token}}`
* real user ip: `x-tpp-userip<span id="1973177c-3174-44a7-bc31-8d826f00a77a" data-renderer-mark="true" data-mark-type="annotation" data-mark-annotation-type="inlineComment" data-id="1973177c-3174-44a7-bc31-8d826f00a77a">: {{userip}}</span>`
  * only when the request is initiated by the user
  * when from the TPP (background refresh), this is not needed

> :warning: TPPs should only pass the user ip when the call is initiated by the user.
> The TPP should not provide any IP that is not triggered by the user.

> :warning: TPP should provide a unique `device_token` per client/device connection.   `device_token` must be a valid UUID v4 as per RFC 4122.

##### Importance of `x-tpp-userip`

All calls initiated by the user (manual refresh or initial generation of access & refresh token) must include the IP address of the user in the `x-tpp-userip` header. From a technical point of view, providing this IP address** guarantees us to identify proper user calls** and to  **protect the integrity of our services** .

Since our Fallback API is based on our original API for our mobile and web apps, there are a lot of security measures built-in. Many of these security measures track the end-user IP addresses and prevent frequent calls from different IP addresses for the same user (amongst other features, that we do not disclose for security reasons). If a TPP doesn't provide an end-user’s IP address with API requests requiring IP specification, or tries to manipulate or obfuscate IP addresses, such cases will be treated in accordance to our established security policies applied to the original API.

> :warning: According to PSD2 (Level1) Art. 94 (1) we require the end-user IP to be specified with every end-user generated request. Monitoring end-user IPs on the N26 side is necessary to safeguard the prevention, investigation and detection of payment fraud. In case N26 security measures applied to the API detect unusual user-related activity, such cases will be processed in accordance with the established security policies, including (but not limited to) rate limiting, blocking request by IP and reporting such cases to the regulatory authorities.

#### Data which should not be stored  :warning:

As per Art 22 (1), (2b) and Art 33(5a) of [Directive (EU) 2015/2366 of the European Parliament and of the Council with regard to regulatory technical standards for strong customer authentication and common and secure open standards of communication](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=uriserv:OJ.L_.2018.069.01.0023.01.ENG&toc=OJ:L:2018:069:TOC##d1e1565-23-1 "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=uriserv:OJ.L_.2018.069.01.0023.01.ENG&toc=OJ:L:2018:069:TOC##d1e1565-23-1") TPP should **NOT store the password** of users!

> CHAPTER IV
>
> CONFIDENTIALITY AND INTEGRITY OF THE PAYMENT SERVICE USERS' PERSONALISED SECURITY CREDENTIALS
>
> Article 22
>
> Payment service providers shall ensure the confidentiality and integrity of the personalised security credentials of the payment service user, including authentication codes, during all phases of the authentication.
>
> For the purpose of paragraph 1, payment service providers shall ensure that each of the following requirements is met:
>
> a) […]
>
> b) personalised security credentials in data format, as well as cryptographic materials related to the encryption of the personalised security credentials are not stored in plain text;

> Section 2
>
> Specific requirements for the common and secure open standards of communication
>
> Article 33
>
> Contingency measures for a dedicated interface
>
> […]
>
> For this purpose, account servicing payment service providers shall ensure that the payment service providers referred to in Article 30(1) can be identified and can rely on the authentication procedures provided by the account servicing payment service provider to the payment service user. Where the payment service providers referred to in Article 30(1) make use of the interface referred to in paragraph 4 they shall:
>
> a) take the necessary measures to ensure that they do not access, store or process data for purposes other than for the provision of the service as requested by the payment service user;

> :warning: If we identify the TPP is doing this, we reserve the right to block those accesses.

#### Validity of access & refresh tokens


|                | **Access Token**                                                                  | **Refresh Token**                                                                   |
| ---------------- |-----------------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| **Purpose**    | Access for API calls in **one session**                                           | Generate new access tokens                                                          |
| **How to get** | 1. Email & password with **Push**(OOB) or SMS (OTP). Or 2. Existing Refresh token | 1. Email & password  with **Push**(OOB) or SMS (OTP). Or  2. Existing Refresh token |
| **Validity**   | 15 min                                                                            | **One time usable** , but chain of refresh tokens is **valid for 90 days**          |
| **Storage**    | NEVER                                                                             | Yes, for 89 days (expiry needs to be stored on TPP)                                 |

> :information_source: **Refreshing refresh tokens**
> The first refresh token has validity of 180 days, but is  **one-time usable** .
> With this refresh token, an access and a new refresh token can be requested.
> This new refresh token maintains the initial 180 day validity.
> So in summary the chain of refresh tokens has a validity of 180 days.

> :information_source: **Refresh getting close to expiry**
> On day 179 the TPP should discard the refresh token and ask the user re-authentication.
> As highlighted above the TPP should never store the password of the user.

> :warning: Access tokens are supposed to be used only for  **1 session (sequence of calls)** .
> If a user requests a manual refresh a new access token has to be requested **EVEN** if the original access token is still valid.
> For this reason the TPP should **NEVER** store the access token.

> :warning: The TPP should not use those access and refresh tokens on other base URLs than `aisp.tech26.de`.

> :x: If those policies above are not respected, there is no guarantee you will not be rate-limited.

## User Authentication

### Overview

![User Authentication](./assets/fallback-user-auth-flow.png)

### Start authentication with username & password

#### Request

```
POST /oauth2/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
device-token: {{device_token}}
x-tpp-userip: {{userip}}

username={{username}}&password={{password}}&grant_type=password
```

##### Parameters

`device_token` is a unique identifier of device. Has to be the same per installation.

For syncs from the backend, this has to be unique and persisted per user.

`userip` has be populated with the real user ip.

> :information_source: Only the headers mentioned here are necessary

#### Responses

##### Successful

```
HTTP/1.1 403 Forbidden
{
  "status": 403,
  "error": "mfa_required",
  "mfaToken": {{mfaToken}},
  "hostUrl": "{{hostUrl}}",
  "detail": "mfa_required",
  "userMessage": {
    "title": "MFA token is required",
    "detail": "MFA token is required"
  }
}
```

##### Parameters

###### mfaToken

`mfaToken` is unique token of this login try. If is required for the subsequent Authentication requests.

##### Invalid credentials/username does not exist

```
HTTP/1.1 400 Forbidden
{
  "error": "invalid_grant",
  "error_description": "Bad credentials",
  "status": 400,
  "detail": "Bad credentials",
  "userMessage": {
    "title": "Login failed",
    "detail": "Incorrect user name or password! Please, try again"
  }
}
```

##### User was rate-limited

```
HTTP/1.1 429 Too Many Requests
{
  "error": "too_many_requests",
  "error_description": "Too many log-in attempts. Please try again in 30 minutes.",
  "status": 429,
  "detail": "Too Many Requests",
  "userMessage": {
    "title": "Too Many Requests",
    "detail": "Too many log-in attempts. Please try again in 30 minutes."
  }
}
```

##### No x-tpp-userip header was provided

```
HTTP/1.1 451 Unavailable For Legal Reasons
{
  "error": "Oops!",
  "status": 451,
  "detail": "Please try again later.",
  "userMessage": {
    "title": "Oops!",
    "detail": "Please try again later."
   },
}
```

### Continue authentication with Two-Step Certification (OOB) - Recommended

#### Request

```
POST /api/mfa/challenge HTTP/1.1
Content-Type: application/json
device-token: {{device_token}}
x-tpp-userip: {{userip}}
 
{ 
   "mfaToken": "{{mfaToken}}",
   "challengeType": "oob"
}
```

#### Responses

##### Successful

```
HTTP/1.1 200 OK
{
    "challengeType": "oob"
}
```

User received a push notification with the request to authorise this connection.

##### Unsuccessful

In case `device_token` is incorrect or `mfa_token` is incorrect.

```
HTTP/1.1 400 Bad Request
{
  "error": "invalid_grant",
  "error_description": "Bad credentials",
  "status": 400,
  "detail": "Bad credentials",
  "userMessage": {
    "title": "Login failed",
    "detail": "Session has expired or is not valid! Please, try again"
  }
}
```

##### User does not have a paired device

```
HTTP/1.1 403 Forbidden
{
  "error": "invalid_state",
  "error_description": "Invalid state to start the challenge",
  "status": 403,
  "detail": "Invalid state to start the challenge",
  "userMessage": {
    "title": "Login failed",
    "detail": "Invalid state to start the challenge"
  }
}
```

In this case, please proceed to the OTP flow.

### Continue authentication with Two-Step SMS (OTP) - Not Recommended

Reasons why SMS is not recommended:

* SMS delivery rate is not 100%
* SMS delivery takes time
* We limit how many SMS a user can use
* Users might have changed the phone number and not informed us

#### Request

```
POST /api/mfa/challenge HTTP/1.1
Content-Type: application/json
device-token: {{device_token}}
x-tpp-userip: {{userip}}
 
{ 
   "mfaToken": "{{mfaToken}}",
   "challengeType": "otp"
}
```

#### Responses

##### Successful

```
HTTP/1.1 201 Created
{
    "challengeType": "otp",
    "remainingResendCodeCount": {{remainingResendCodeCount}},
    "waitingTimeInSeconds": {{waitingTimeInSeconds}},
    "obfuscatedPhoneNumber": "{{obfuscatedPhoneNumber}}"
}
```

An SMS was sent to the user with the request to authorise this connection.

###### Parameters

`remainingResendCodeCount` (int) - amount of remaining resend attempts

`waitingTimeInSeconds` (int) - amount of time the client needs to wait before the next SMS send request

`obfuscatedPhoneNumber` - the phone number where the SMS has been sent to, e.g. "+49******0285"

##### Successful resent the SMS

```
HTTP/1.1 200 Ok
{
    "challengeType": "otp",
    "remainingResendCodeCount": {{remainingResendCodeCount}},
    "waitingTimeInSeconds": {{waitingTimeInSeconds}},
    "obfuscatedPhoneNumber": "{{obfuscatedPhoneNumber}}"
}
```

An SMS was resent to the user with the request to authorise this connection.

###### Parameters

`remainingResendCodeCount` (int) - amount of remaining resend attempts

`waitingTimeInSeconds` (int) - amount of time the client needs to wait before the next SMS send request

`obfuscatedPhoneNumber` - the phone number where the SMS has been sent to, e.g. "+49******0285"

##### SMS sent successfully less than 30 seconds ago

```
HTTP/1.1 204 No content
```

##### Unsuccessful

In case `device_token` is incorrect or `mfa_token` is incorrect.

```
HTTP/1.1 400 Forbidden
{
  "error": "invalid_grant",
  "error_description": "Bad credentials",
  "status": 400,
  "detail": "Bad credentials",
  "userMessage": {
    "title": "Login failed",
    "detail": "Session has expired or is not valid! Please, try again"
  }
}
```

##### SMS retry limit is reached

```
HTTP/1.1 429 Too Many Requests
{
  "error": "too_many_sms",
  "error_description": "Too many SMS have been sent. Please try again in 1 day.",
  "status": 429,
  "detail": "Too Many SMS",
  "userMessage": {
    "title": "Too Many SMS",
    "detail": "Too many SMS have been sent. Please try again in 1 day."
  }
}
```

### Get access and refresh tokens

#### Request for `OOB`

```
POST /oauth2/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
device-token: {{device_token}}
x-tpp-userip: {{userip}}
 
mfaToken={{mfaToken}}&grant_type=mfa_oob
```

> :information_source: The TPP should poll this endpoint not more than every 2 seconds.
> After a successful, expired or unauthorized response the polling should stop.

#### Responses for `OOB`

##### Successful

```
HTTP/1.1 200 OK
{
    "access_token": "{{access_token}}",
    "token_type": "bearer",
    "refresh_token": "{{refresh_token}}",
    "expires_in": {{expires_in}},
    "scope": "trust",
    "host_url": "{{host_url}}"
}
```

##### User has not yet provided authorisation

```
HTTP/1.1 400 Bad Request
{
  "error": "authorization_pending",
  "error_description": "MFA token was not yet confirmed",
  "status": 400,
  "detail": "MFA token was not yet confirmed",
  "userMessage": {
    "title": "Login failed",
    "detail": "Authorisation request is not confirmed. Please, confirm it on your device and try again."
  }
}
```

#### Request for `OTP`

```
POST /oauth2/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
device-token: {{device_token}}
x-tpp-userip: {{userip}}
 
mfaToken={{mfaToken}}&otp={{otp}}&grant_type=mfa_otp
```

##### Parameters

`otp` is the one-time password that user will received as an SMS and has to enter in the flow.

#### Responses for`otp`

##### Successful

```
HTTP/1.1 200 OK
{
    "access_token": "{{access_token}}",
    "token_type": "bearer",
    "refresh_token": "{{refresh_token}}",
    "expires_in": {{expires_in}},
    "scope": "trust",
    "host_url": "{{host_url}}"
}
```

##### User has provided the wrong code

```
HTTP/1.1 400 Bad Request
{
  "error": "invalid_otp",
  "error_description": "OTP is invalid",
  "status": 400,
  "detail": "OTP is invalid",
  "userMessage": {
    "title": "Invalid code",
    "detail": "Provided code is invalid. Please, try again."
  }
}
```

##### Unsuccessful

If `device_token` is incorrect, `mfa_token` is incorrect or expired in 5 minutes.

```
HTTP/1.1 400 Bad Request
{
  "error": "invalid_grant",
  "error_description": "Bad credentials",
  "status": 400,
  "detail": "Bad credentials",
  "userMessage": {
    "title": "Login failed",
    "detail": "Session has expired or is not valid! Please, try again"
  }
}
```

##### Too many code attempts (SMS must be resent)

```
HTTP/1.1 429 Too Many Requests
{
  "error": "too_many_attempts",
  "error_description": "Amount of the attempts has been exceeded. Please resend the SMS.",
  "status": 429,
  "detail": "Amount of the attempts has been exceeded. Please resend the SMS.",
  "userMessage": {
    "title": "Too many attempts",
    "detail": "Amount of the attempts has been exceeded. Please resend the SMS."
  }
}
```

### Get new access & refresh token from valid refresh token

#### Request

```
POST /oauth2/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
device-token: {{device_token}}
 
refresh_token={{refresh_token}}&grant_type=refresh_token
```

##### Parameters

`device_token` is a unique identifier of device. Has to be the same per installation.

For syncs from the backend, this has to be unique and persisted per user.

`refresh_token` is the valid stored refresh token.

#### Responses

##### Successful

```
HTTP/1.1 200 OK
{
    "access_token": "{{access_token}}",
    "token_type": "bearer",
    "refresh_token": "{{refresh_token}}",
    "expires_in": {{expires_in}},
    "scope": "trust",
    "host_url": "{{host_url}}"
}
```

##### Parameters

`access_token` is the token which is needed for subsequent API calls

`refresh_token` is the new 1-time usable refresh token

`expires_in` is the expiration time of the new access token in seconds

##### Refresh token expired or used more than once

```
HTTP/1.1 401 Unauthorized
{
    "status": 401,
    "detail": "Refresh token not found!",
    "type": "invalid_grant",
    "userMessage": {
        "title": "error.oauth2.invalid_refresh_token.title",
        "detail": "error.oauth2.invalid_refresh_token.detail"
    },
    "error": "invalid_grant",
    "error_description": "Refresh token not found!"
}
```

> :warning: On a `401` response the TPP has to refresh tokens.    
**Note:**     
Receiving a `401` indicates that the usage of access and refresh tokens is not as defined in [Validity of access 
> &amp; refresh tokens](./fallback-aisp.md#validity-of-access--refresh-tokens).

## Account information


### Get accounts information

#### Request

```
GET    /api/v2/accounts HTTP/1.1
Authorization: bearer {{access_token}}
x-tpp-userip: {{userip}}
device-token: {{device_token}}
```

#### Response

<details>
  <summary>Show full transaction response (click to expand)</summary>

```json 
{
  "accounts": [
    {
      "resourceId": "6d3fc103-23c1-429c-9809-fc7672ea21c1",
      "iban": "DE05100110012802645265",
      "currency": "EUR",
      "product": "Joint Account",
      "name": "Aiyana & Wayne",
      "bic": "NTSBDEB1XXX",
      "cashAccountType": "CACC",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/6d3fc103-23c1-429c-9809-fc7672ea21c1/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/6d3fc103-23c1-429c-9809-fc7672ea21c1/transactions"
        }
      }
    },
    {
      "resourceId": "a128ed07-5437-4f4f-9377-a7c0466ce9ef",
      "currency": "EUR",
      "product": "Individual Space",
      "name": "trip space",
      "cashAccountType": "TRAN",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/a128ed07-5437-4f4f-9377-a7c0466ce9ef/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/a128ed07-5437-4f4f-9377-a7c0466ce9ef/transactions"
        }
      }
    },
    {
      "resourceId": "62a56502-4547-4447-9383-9dbf97aedb82",
      "currency": "EUR",
      "product": "Shared Space",
      "name": "apartment space",
      "cashAccountType": "TRAN",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/62a56502-4547-4447-9383-9dbf97aedb82/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/62a56502-4547-4447-9383-9dbf97aedb82/transactions"
        }
      }
    },
    {
      "resourceId": "543de370-0654-4cd6-8213-051bc0cf435a",
      "iban": "DE73100110012852278456",
      "currency": "EUR",
      "product": "Individual Current Account",
      "name": "Main Account",
      "bic": "NTSBDEB1XXX",
      "cashAccountType": "CACC",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/543de370-0654-4cd6-8213-051bc0cf435a/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/543de370-0654-4cd6-8213-051bc0cf435a/transactions"
        }
      }
    },
    {
      "resourceId": "142a69b6-d9a3-43db-a641-b082159bee2b",
      "currency": "EUR",
      "product": "Individual Space",
      "name": "house space",
      "cashAccountType": "TRAN",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/142a69b6-d9a3-43db-a641-b082159bee2b/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/142a69b6-d9a3-43db-a641-b082159bee2b/transactions"
        }
      }
    },
    {
      "resourceId": "80ff6dfb-c1c5-44d0-bc81-f6de437ebd06",
      "iban": "DE16100110012703791106",
      "currency": "EUR",
      "product": "Individual Space",
      "name": "car space",
      "bic": "NTSBDEB1XXX",
      "cashAccountType": "CACC",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/80ff6dfb-c1c5-44d0-bc81-f6de437ebd06/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/80ff6dfb-c1c5-44d0-bc81-f6de437ebd06/transactions"
        }
      }
    },
    {
      "resourceId": "5a15a96b-0765-4d40-bbc3-05e5b5688297",
      "iban": "DE50100110012583312129",
      "currency": "EUR",
      "product": "Individual Instant Saving",
      "name": "Instant Savings",
      "bic": "NTSBDEB1XXX",
      "cashAccountType": "SVGS",
      "status": "enabled",
      "usage": "PRIV",
      "ownerName": "Aiyana Hartmann",
      "_links": {
        "balances": {
          "href": "/v1/berlin-group/v1/accounts/5a15a96b-0765-4d40-bbc3-05e5b5688297/balances"
        },
        "transactions": {
          "href": "/v1/berlin-group/v1/accounts/5a15a96b-0765-4d40-bbc3-05e5b5688297/transactions"
        }
      }
    }
  ]
}
```
</details>


### Get a single account information

#### Request

```
GET    /api/v2/accounts/{accountId} HTTP/1.1
Authorization: bearer {{access_token}}
x-tpp-userip: {{userip}}
device-token: {{device_token}}
```

#### Response

```json
{
   "resourceId": "543de370-0654-4cd6-8213-051bc0cf435a",
   "iban": "DE73100110012852278456",
   "currency": "EUR",
   "product": "Individual Current Account",
   "name": "Main Account",
   "bic": "NTSBDEB1XXX",
   "cashAccountType": "CACC",
   "status": "enabled",
   "usage": "PRIV",
   "ownerName": "Aiyana Hartmann",
   "_links": {
      "balances": {
         "href": "/v1/berlin-group/v1/accounts/543de370-0654-4cd6-8213-051bc0cf435a/balances"
      },
      "transactions": {
         "href": "/v1/berlin-group/v1/accounts/543de370-0654-4cd6-8213-051bc0cf435a/transactions"
      }
   }
}
```

## Account Transactions

### Get account transactions
#### Request

```
GET    /api/fallback/accounts/{accountId}/transactions HTTP/1.1
Authorization: bearer {{access_token}}
x-tpp-userip: {{userip}}
device-token: {{device_token}}
```

##### Parameters

`from` from timestamp, Unixtime

`to` to timestamp, Unixtime

For instance:

```
GET /api/fallback/accounts/91656fc9-4489-4f97-8d33-c5b327df8d8b/transactions?from=1570312800000&to=1570312800001
```

#### Response

```
[
    {
        "id": "48466e5e-72d6-4846-858d-9dbe74cd80c5",
        "accountId": "91656fc9-4489-4f97-8d33-c5b327df8d8b",
        "amount": -0.61,
        "currency": "EUR",
        "referenceText": "reference text",
        "displayTimestamp": "1570313800000",
        "status": "TRANSACTION_STATUS_SUCCEEDED",
        "type": "TRANSACTION_TYPE_DT",
        "paymentScheme": "PAYMENT_SCHEME_SEPA",
        "category": "CATEGORY_FAMILY_AND_FRIENDS",
        "transactionMetadata": {
            "partnerBic": "SOGEDEFFXXX",
            "partnerIban": "DE75512108001245126199",
            "operationType": "HOLD",
            "initiatorUserId": "206a9bbb-d440-409d-95ed-d2eb13dbac78",
            "sepaTransactionId": "c6aa8d21fde743e5a0e13ac3d9b9ed82",
            "partnerAccountName": "Jhon"
        }
    },
    {...}
]
```

### Get Account Transaction Details

#### Request

```
GET    /api/fallback/accounts/{accountId}/transactions/{transactionId} HTTP/1.1
Authorization: bearer {{access_token}}
x-tpp-userip: {{userip}}
device-token: {{device_token}}
```

#### Response

```
{
  "id": "48466e5e-72d6-4846-858d-9dbe74cd80c5",
  "accountId": "91656fc9-4489-4f97-8d33-c5b327df8d8b",
  "amount": -0.61,
  "currency": "EUR",
  "referenceText": "reference text",
  "displayTimestamp": "1570313800000",
  "status": "TRANSACTION_STATUS_SUCCEEDED",
  "type": "TRANSACTION_TYPE_DT",
  "paymentScheme": "PAYMENT_SCHEME_SEPA",
  "category": "CATEGORY_FAMILY_AND_FRIENDS",
  "transactionMetadata": {
      "partnerBic": "SOGEDEFFXXX",
      "partnerIban": "DE75512108001245126199",
      "operationType": "HOLD",
      "initiatorUserId": "206a9bbb-d440-409d-95ed-d2eb13dbac78",
      "sepaTransactionId": "c6aa8d21fde743e5a0e13ac3d9b9ed82",
      "partnerAccountName": "Jhon"
  }
}
```
