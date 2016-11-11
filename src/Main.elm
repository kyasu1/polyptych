module Main exposing (..)

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)


type alias Model =
    { canvas : Size
    , frame : Frame
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
        --    , frame = SingleImage { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12201-0285-001" }
    , frame =
        HorizontalSplit
            { top = SingleImage { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12201-0285-001" }
            , topHeight = 80
            , bottom = SingleImage { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12101-1115-001" }
            }
    }


type Msg
    = NothingYet


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


viewCanvas : Size -> Frame -> Html Msg
viewCanvas size rootFrame =
    div
        [ style
            [ ( "width", toString size.width ++ "px" )
            , ( "height", toString size.height ++ "px" )
            , ( "border", "2px solid black" )
            ]
        ]
        [ viewFrame size rootFrame ]


viewFrame : Size -> Frame -> Html Msg
viewFrame size frame =
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
                [ viewFrame
                    { width = size.width
                    , height = topHeight
                    }
                    top
                , viewFrame
                    { width = size.width
                    , height = size.height - topHeight
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
        [ viewCanvas model.canvas model.frame
        , hr [] []
        , text <| toString model
        ]


main =
    Html.App.program
        { init = ( initialModel, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }
