
# Chapa Flutter SDK

Chapa Flutter sdk for Chapa payment API. It is not official and is not supported by Chapa. It is provided as-is. The main features of this library is it supports connectivity tests, auto reroutes, parameter checks for payment options.



## API Reference

#### Create new transaction from mobile end point

Base end point
https://api.chapa.co/v1

```http
  POST /transaction/mobile-initialize
```

| Parameter | Type     | Description                |
| :-------- | :------- | :------------------------- |
| `key`      | `string` | **Required**. This will be your public key from Chapa. When on test mode use the test key, and when on live mode use the live key. |
| `email`    | `string` | A customer’s email address. |
| `amount`   | `string` | **Required**. The amount you will be charging your customer. |
| `first_name` | `string` |  A customer’s first name. |
| `last_name`      | `string` |  A customer's last name. |
| `tx_ref`   | `string` | **Required**. A unique reference given to each transaction. |
| `currency` | `string` | **Required**. The currency in which all the charges are made. i.e ETB, USD |
| `phone`    | `digit` |  A customer’s phone number. |
| `callback_url`| `string` |  The URL to redirect the customer to after payment is done.|
| `customization[title]`| `string` |  The customizations field (optional) allows you to customize the look and feel of the payment modal.|

#### SDK requires additional parameter for fallBack page which is named route which will help you reroute webview after payment completed, on internet disconnected and many more



| Parameter | Type     | Description                       |
| :-------- | :------- | :-------------------------------- |
| `namedRouteFallBack`      | `string` | **Required by the sdk**. This will accepted route name in String, After successful transaction the app will direct to this page with necessary information for flutter developers to update the backend or to regenerate new transaction reference. |




## Installation

Installation instructions coming soon its better if you install it from pub dev



## Usage/Example

```flutter
import 'package:chapasdk/chapasdk.dart';


Chapa.paymentParameters(
        context: context, // context 
        publicKey: 'CHASECK_TEST--------------',
        currency: 'ETB',
        amount: '200',
        email: 'xyz@gmail.com',
        phone: '911223344',
        firstName: 'fullName',
        lastName: 'lastName',
        txRef: '34TXTHHgb',
        title: 'title',
        desc:'desc',
        namedRouteFallBack: '/second', // fall back route name
       );
```


## FAQ

#### Should my fallBack route should be named route?

Answer Yes, the fallBackRoute comes with an information such as payment is successful, user cancelled payment and connectivity issue messages. Those information will help you to update your backend, to generate new transaction reference.


