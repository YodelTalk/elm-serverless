port module Pipelines.API exposing (main)

import Serverless
import Serverless.Conn exposing (header, mapUnsent, respond, toSent, updateResponse)
import Serverless.Conn.Body exposing (text)
import Serverless.Conn.Response exposing (addHeader, setBody, setStatus)
import Serverless.Plug as Plug exposing (Plug, plug)


{-| Pipelines demo.

Pipelines are sequences of functions which transform the connection. They are
ideal for building middelware.

-}
main : Serverless.Program () () () () ()
main =
    Serverless.httpApi
        { configDecoder = Serverless.noConfig
        , initialModel = ()
        , parseRoute = Serverless.noRoutes
        , update = Serverless.noSideEffects
        , interop = Serverless.noInterop
        , requestPort = requestPort
        , responsePort = responsePort

        -- `Plug.apply` transforms the connection by passing it through each plug
        -- in a pipeline. After the pipeline is processed, the conn may already
        -- be in a "sent" state, so we use `mapUnsent` to conditionally apply
        -- the final responder.
        --
        -- Even if we didn't use `mapUnsent`, no harm could be done, as a sent
        -- conn is immutable.
        , endpoint =
            Plug.apply pipeline
                >> mapUnsent (respond ( 200, text "Pipeline applied" ))
        }


pipeline : Plug () () () ()
pipeline =
    Plug.pipeline
        -- Each plug in a pipeline transforms the connection
        |> plug
            (updateResponse <|
                addHeader ( "x-from-first-plug", "foo" )
            )
        -- Some plugs may choose to send a response early. This can
        -- be done with the `toSent` function, which will make the conn
        -- immutable. `Plug.apply` will skip the remainder of the plugs during
        -- processing if at any point the conn becomes "sent".
        |> plug
            (\conn ->
                case header "authorization" conn of
                    Just _ ->
                        -- real auth would validate this
                        conn

                    Nothing ->
                        conn
                            |> updateResponse
                                (setBody (text "Unauthorized: Set an Authorization header using curl or postman (value does not matter)")
                                    >> setStatus 401
                                )
                            |> toSent
            )
        |> plug
            (updateResponse <|
                addHeader ( "x-from-last-plug", "bar" )
            )


port requestPort : Serverless.RequestPort msg


port responsePort : Serverless.ResponsePort msg
