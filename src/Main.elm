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
    , dragState : Maybe Mouse.Position
    }


type alias Size =
    { width : Int, height : Int }


type Frame
    = SingleImage { url : String }
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
        HorizontalSplit
            { top = SingleImage { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12201-0285-001" }
            , topHeight = 80
            , bottom = SingleImage { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12101-1115-001" }
            }
    , dragState = Nothing
    }


type Msg
    = DragDividerStart Mouse.Position
    | DragMove Mouse.Position
    | DragEnd Mouse.Position


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        DragDividerStart position ->
            ( { model | dragState = Just position }, Cmd.none )

        DragMove currentPosition ->
            case model.dragState of
                Just startPosition ->
                    ( { model
                        | frame = applyDrag (currentPosition.y - startPosition.y) model.frame
                        , dragState = Just currentPosition
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        DragEnd endPosition ->
            ( { model | dragState = Nothing }, Cmd.none )


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
        SingleImage { url } ->
            div
                [ style
                    [ ( "background-image", "url(" ++ url ++ ")" )
                    , ( "background-size", "auto " ++ toString size.height ++ "px" )
                    , ( "width", toString size.width ++ "px" )
                    , ( "height", toString size.height ++ "px" )
                    ]
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
    case model.dragState of
        Nothing ->
            Sub.none

        Just _ ->
            Sub.batch
                [ Mouse.moves DragMove
                , Mouse.ups DragEnd
                ]


main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
