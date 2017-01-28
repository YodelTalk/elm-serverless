module Serverless.Plug exposing (..)

{-| Build pipelines of plugs.

## Table of Contents

* [Types](#types)
* [Building Pipelines](#building-pipelines)

## Types

The following types are used to define a pipeline, but do not deal with these
directly. Use the functions under [Building Pipelines](#building-pipelines)
instead.

@docs Plug, Pipeline

## Building Pipelines

Use these functions to build your pipelines. For example,

    myPipeline =
        pipeline
            |> plug simplePlugA
            |> plug simplePlugB
            |> loop loadSomeDatabaseStuff
            |> nest anotherPipeline
            |> fork router

@docs pipeline, toPipeline, plug, loop, nest, fork
-}

import Array exposing (Array)
import Serverless.Conn.Types exposing (Conn)


{-| A plug processes the connection in some way.

There are three types:

* `Plug` a simple plug. It just transforms the connection
* `Loop` an update plug. It may transform the connection, but it also can
  have side effects. Execution will only flow to the next plug when an
  update plug returns no side effects.
* `Pipeline` a sequence of zero or more plugs
-}
type Plug config model msg
    = Plug (Conn config model -> Conn config model)
    | Loop (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    | Router (Conn config model -> Pipeline config model msg)


{-| Represents a list of plugs, each of which processes the connection
-}
type alias Pipeline config model msg =
    Array (Plug config model msg)


{-| Begins a pipeline.

Build the pipeline by chaining simple and update plugs with
`|> plug` and `|> loop` respectively.
-}
pipeline : Pipeline config model msg
pipeline =
    Array.empty


{-| Converts a single function to a pipeline.

For creating a simple pipeline from a responder function when a pipeline is
expected.

    status (Code 404)
        >> body (TextBody "Not found")
        >> send responsePort
        |> toPipeline
-}
toPipeline :
    (Conn config model -> ( Conn config model, Cmd msg ))
    -> Pipeline config model msg
toPipeline responder =
    pipeline |> loop (\msg conn -> conn |> responder)


{-| Extend the pipeline with a simple plug.

A plug just transforms the connection. For example,

    pipeline
        |> plug (body (TextBody "foo"))
-}
plug :
    (Conn config model -> Conn config model)
    -> Pipeline config model msg
    -> Pipeline config model msg
plug plug pipeline =
    pipeline |> Array.push (Plug plug)


{-| Extends the pipeline with an update plug.

An update plug can transform the connection and or return a side effect (`Cmd`).
Loop plugs should use `pipelinePause` and `pipelineResume` when working with side
effects. They are defined in the `Serverless.Conn` module.

    -- Loop plug which does nothing
    pipeline
        |> loop (\msg conn -> (conn, Cmd.none))
-}
loop :
    (msg -> Conn config model -> ( Conn config model, Cmd msg ))
    -> Pipeline config model msg
    -> Pipeline config model msg
loop update pipeline =
    pipeline |> Array.push (Loop update)


{-| Nest a child pipeline into a parent pipeline.
-}
nest :
    Pipeline config model msg
    -> Pipeline config model msg
    -> Pipeline config model msg
nest child parent =
    Array.append parent child


{-| Adds a router to the pipeline.

A router can branch a pipeline into many smaller pipelines depending on the
route message passed in.
-}
fork :
    (Conn config model -> Pipeline config model msg)
    -> Pipeline config model msg
    -> Pipeline config model msg
fork router pipeline =
    pipeline |> Array.push (Router router)
