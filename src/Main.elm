module Main exposing (..)

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode
import Mouse


borderColor =
    "tan"


type alias Model =
    { canvas : Size
    , borderSize : Int
    , frame : Frame
    , dragSlideState : Maybe Mouse.Position
    , dragImageState : Maybe Mouse.Position
    }


type alias Size =
    { width : Int, height : Int }


type alias Position =
    { x : Int, y : Int }


type alias Image =
    { url : String
    , size : Size
    , offset : Position
    }


type Frame
    = SingleImage Image
    | HorizontalSplit
        { top : Frame
        , topHeight : Int
        , bottom : Frame
        }


initialModel : Model
initialModel =
    { canvas =
        { width = 250, height = 250 }
    , borderSize = 5
    , frame =
        --        HorizontalSplit
        --            { top =
        SingleImage
            { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12201-0285-001"
            , size = { width = 640, height = 640 }
            , offset = { x = 0, y = 0 }
            }
        --            , topHeight = 80
        --            , bottom =
        --                SingleImage
        --                    { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12101-1115-001"
        --                    , size = { width = 640, height = 640 }
        --                    , offset = { x = 0, y = 0 }
        --                    }
        --            }
    , dragSlideState = Nothing
    , dragImageState = Nothing
    }


type Msg
    = DragDividerStart Mouse.Position
    | DragImageStart Mouse.Position
    | DragMove Mouse.Position
    | DragEnd Mouse.Position


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        DragDividerStart position ->
            ( { model | dragSlideState = Just position }, Cmd.none )

        DragImageStart position ->
            ( { model | dragImageState = Just position }
            , Cmd.none
            )

        DragMove currentPosition ->
            case model.dragSlideState of
                Just startPosition ->
                    ( { model
                        | frame = applyDrag (currentPosition.y - startPosition.y) model.frame
                        , dragSlideState = Just currentPosition
                      }
                    , Cmd.none
                    )

                Nothing ->
                    case model.dragImageState of
                        Just startPosition ->
                            ( { model
                                | frame =
                                    applyImageDrag
                                        { x = startPosition.x - currentPosition.x
                                        , y = startPosition.y - currentPosition.y
                                        }
                                        model.frame
                                , dragImageState = Just currentPosition
                              }
                            , Cmd.none
                            )

                        Nothing ->
                            ( model, Cmd.none )

        DragEnd endPosition ->
            ( { model
                | dragSlideState = Nothing
                , dragImageState = Nothing
              }
            , Cmd.none
            )


applyImageDrag : Position -> Frame -> Frame
applyImageDrag change frame =
    case frame of
        SingleImage image ->
            SingleImage
                { image
                    | offset =
                        { x = image.offset.x + change.x
                        , y = image.offset.y + change.y
                        }
                }

        HorizontalSplit _ ->
            frame


applyDrag : Int -> Frame -> Frame
applyDrag yChange frame =
    case frame of
        HorizontalSplit { top, topHeight, bottom } ->
            HorizontalSplit { top = top, bottom = bottom, topHeight = topHeight + yChange }

        SingleImage _ ->
            frame


viewCanvas : Int -> Size -> Frame -> Html Msg
viewCanvas borderSize size rootFrame =
    div
        [ style
            [ ( "width", toString size.width ++ "px" )
            , ( "height", toString size.height ++ "px" )
            , ( "border", "2px solid black" )
            ]
        ]
        [ div
            [ style
                [ ( "border", toString borderSize ++ "px solid " ++ borderColor ) ]
            ]
            [ viewFrame
                borderSize
                { width = size.width - 2 * borderSize
                , height = size.height - 2 * borderSize
                }
                rootFrame
            ]
        ]


viewFrame : Int -> Size -> Frame -> Html Msg
viewFrame borderSize size frame =
    case frame of
        SingleImage image ->
            let
                imageRatio =
                    toFloat image.size.width / toFloat image.size.height

                frameRatio =
                    toFloat size.width / toFloat size.height
            in
                div
                    [ style
                        [ ( "background-image", "url(" ++ image.url ++ ")" )
                        , ( "background-size"
                          , if imageRatio > frameRatio then
                                "auto " ++ toString size.height ++ "px"
                            else
                                toString size.width ++ "px auto"
                          )
                        , ( "width", toString size.width ++ "px" )
                        , ( "height", toString size.height ++ "px" )
                        , ( "background-position", toString -image.offset.x ++ "px " ++ toString -image.offset.y ++ "px" )
                        ]
                    , Html.Events.on "mousedown" (Json.Decode.map DragImageStart Mouse.position)
                    ]
                    []

        HorizontalSplit { top, topHeight, bottom } ->
            div []
                [ viewFrame borderSize
                    { width = size.width
                    , height = topHeight
                    }
                    top
                , div
                    [ style
                        [ ( "width", toString size.width ++ "px" )
                        , ( "height", toString borderSize ++ "px" )
                        , ( "background-color", borderColor )
                        , ( "cursor", "ns-resize" )
                        ]
                    , Html.Events.on "mousedown" (Json.Decode.map DragDividerStart Mouse.position)
                    ]
                    []
                , viewFrame borderSize
                    { width = size.width
                    , height = size.height - topHeight - borderSize
                    }
                    bottom
                ]


view : Model -> Html.Html Msg
view model =
    div
        [ style
            [ ( "padding", "8px" )
            ]
        ]
        [ viewCanvas model.borderSize model.canvas model.frame
        , hr [] []
        , text <| toString model
        ]


subscriptions model =
    case ( model.dragSlideState, model.dragImageState ) of
        ( Just _, _ ) ->
            Sub.batch
                [ Mouse.moves DragMove
                , Mouse.ups DragEnd
                ]

        ( _, Just _ ) ->
            Sub.batch
                [ Mouse.moves DragMove
                , Mouse.ups DragEnd
                ]

        _ ->
            Sub.none


main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
