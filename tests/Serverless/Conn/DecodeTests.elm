module Serverless.Conn.DecodeTests exposing (all)

import Serverless.Conn.Body as Body exposing (Body)
import Serverless.Conn.IpAddress as IpAddress exposing (IpAddress)
import Serverless.Conn.KeyValueList as KeyValueList
import Serverless.Conn.Request as Request
import Test exposing (describe)
import Test.Extra exposing (describeDecoder, DecoderExpectation(..))


all : Test.Test
all =
    describe "Serverless.Conn.Decode"
        [ describeDecoder "KeyValueList.decoder"
            KeyValueList.decoder
            [ ( "null", DecodesTo [] )
            , ( "{}", DecodesTo [] )
            , ( """{ "fOo": "baR " }""", DecodesTo [ ( "fOo", "baR " ) ] )
            , ( """{ "foo": 3 }""", FailsToDecode )
            ]
        , describeDecoder "body"
            Body.decoder
            [ ( "null", DecodesTo Body.empty )
            , ( "\"\"", DecodesTo (Body.text "") )
            , ( "\"foo bar\\ncar\"", DecodesTo (Body.text "foo bar\ncar") )
            , ( "\"{}\"", DecodesTo (Body.text "{}") )
            ]
        , describeDecoder "ip"
            IpAddress.decoder
            [ ( "null", FailsToDecode )
            , ( "\"\"", FailsToDecode )
            , ( "\"1.2.3\"", FailsToDecode )
            , ( "\"1.2.3.4\"", DecodesTo (IpAddress.ip4 1 2 3 4) )
            , ( "\"1.2.3.4.5\"", FailsToDecode )
            , ( "\"1.2.-3.4\"", FailsToDecode )
            ]
        , describeDecoder "Request.methodDecoder"
            Request.methodDecoder
            [ ( "null", FailsToDecode )
            , ( "\"\"", FailsToDecode )
            , ( "\"fizz\"", FailsToDecode )
            , ( "\"GET\"", DecodesTo Request.GET )
            , ( "\"get\"", DecodesTo Request.GET )
            , ( "\"gEt\"", DecodesTo Request.GET )
            , ( "\"POST\"", DecodesTo Request.POST )
            , ( "\"PUT\"", DecodesTo Request.PUT )
            , ( "\"DELETE\"", DecodesTo Request.DELETE )
            , ( "\"OPTIONS\"", DecodesTo Request.OPTIONS )
            , ( "\"Trace\"", DecodesTo Request.TRACE )
            , ( "\"head\"", DecodesTo Request.HEAD )
            , ( "\"PATCH\"", DecodesTo Request.PATCH )
            ]
        , describeDecoder "Request.schemeDecoder"
            Request.schemeDecoder
            [ ( "null", FailsToDecode )
            , ( "\"\"", FailsToDecode )
            , ( "\"http\"", DecodesTo Request.Http )
            , ( "\"https\"", DecodesTo Request.Https )
            , ( "\"HTTP\"", DecodesTo Request.Http )
            , ( "\"httpsx\"", FailsToDecode )
            ]
        , describeDecoder "Request.decoder"
            Request.decoder
            [ ( "", FailsToDecode )
            , ( "{}", FailsToDecode )
            , ( """
            {
              "id": "some-id",
              "body": null,
              "headers": null,
              "host": "",
              "method": "GeT",
              "path": "/",
              "port": 80,
              "remoteIp": "127.0.0.1",
              "scheme": "http",
              "stage": "test",
              "queryParams": null,
              "queryString": ""
            }
            """
              , DecodesTo (Request.init "some-id")
              )
            ]
        ]
