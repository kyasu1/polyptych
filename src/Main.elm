module Main exposing (..)

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode
import Mouse
import ImageSearch


borderColor =
    "tan"


type alias Model =
    { canvas : Size
    , borderSize : Int
    , frame : Frame
    , dragState :
        Maybe { startPosition : Mouse.Position, path : FramePath }
    , imageSearch : ImageSearch.State
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


type alias FramePath =
    List Int


initialModel : Model
initialModel =
    { canvas =
        { width = 250, height = 250 }
    , borderSize = 5
    , frame =
        HorizontalSplit
            { top =
                SingleImage
                    { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12201-0285-001"
                    , size = { width = 640, height = 640 }
                    , offset = { x = 0, y = 0 }
                    }
            , topHeight = 80
            , bottom =
                HorizontalSplit
                    { top =
                        SingleImage
                            { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12201-0167-001"
                            , size = { width = 640, height = 640 }
                            , offset = { x = 0, y = 0 }
                            }
                    , topHeight = 40
                    , bottom =
                        SingleImage
                            { url = "http://item.shopping.c.yimg.jp/i/l/pawnshopiko_12101-1115-001"
                            , size = { width = 640, height = 640 }
                            , offset = { x = 0, y = 0 }
                            }
                    }
            }
    , dragState = Nothing
    , imageSearch = ImageSearch.init
    }


type Msg
    = DragStart FramePath Mouse.Position
    | DragMove Mouse.Position
    | DragEnd Mouse.Position
    | ImageSearchMsg ImageSearch.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        DragStart path position ->
            ( { model | dragState = Just { path = List.reverse path, startPosition = position } }
            , Cmd.none
            )

        DragMove currentPosition ->
            case model.dragState of
                Just { startPosition, path } ->
                    ( { model
                        | frame =
                            applyDrag path
                                { x = startPosition.x - currentPosition.x
                                , y = startPosition.y - currentPosition.y
                                }
                                model.frame
                        , dragState = Just { startPosition = currentPosition, path = path }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        DragEnd endPosition ->
            ( { model
                | dragState = Nothing
              }
            , Cmd.none
            )

        --        ImageSearchMsg (ImageSearch.ImageSelected { url }) ->
        --            ( { model | frame = replaceImage [ 0 ] url model.frame }, Cmd.none )
        ImageSearchMsg childMsg ->
            let
                ( newChildState, childCmd, selectedImage ) =
                    ImageSearch.update childMsg model.imageSearch

                newModel =
                    case selectedImage of
                        Just newImage ->
                            { model
                                | frame = replaceImage [ 0 ] newImage.url model.frame
                            }

                        Nothing ->
                            model
            in
                ( { newModel | imageSearch = newChildState }
                , Cmd.map ImageSearchMsg childCmd
                )


replaceImage : FramePath -> String -> Frame -> Frame
replaceImage path newUrl frame =
    case frame of
        SingleImage currentImage ->
            SingleImage { currentImage | url = newUrl }

        HorizontalSplit current ->
            -- TODO follow the correct path
            HorizontalSplit
                { current | top = replaceImage [] newUrl current.top }


applyDrag : FramePath -> Position -> Frame -> Frame
applyDrag path change frame =
    case frame of
        HorizontalSplit { top, topHeight, bottom } ->
            case path of
                0 :: rest ->
                    HorizontalSplit
                        { top = applyDrag rest change top
                        , topHeight = topHeight
                        , bottom = bottom
                        }

                1 :: rest ->
                    HorizontalSplit
                        { top = top
                        , topHeight = topHeight
                        , bottom = applyDrag rest change bottom
                        }

                _ ->
                    HorizontalSplit
                        { top = top
                        , topHeight = topHeight - change.y
                        , bottom = bottom
                        }

        SingleImage image ->
            SingleImage
                { image
                    | offset =
                        { x = image.offset.x + change.x
                        , y = image.offset.y + change.y
                        }
                }


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
            [ viewFrame []
                borderSize
                { width = size.width - 2 * borderSize
                , height = size.height - 2 * borderSize
                }
                rootFrame
            ]
        ]


viewFrame : FramePath -> Int -> Size -> Frame -> Html Msg
viewFrame path borderSize size frame =
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
                    , Html.Events.on "mousedown" (Json.Decode.map (DragStart path) Mouse.position)
                    ]
                    []

        HorizontalSplit { top, topHeight, bottom } ->
            div []
                [ viewFrame (0 :: path)
                    borderSize
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
                    , Html.Events.on "mousedown" (Json.Decode.map (DragStart path) Mouse.position)
                    ]
                    []
                , viewFrame (1 :: path)
                    borderSize
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
        , div
            [ style
                [ ( "position", "absolute" )
                , ( "right", "0px" )
                , ( "top", "0px" )
                ]
            ]
            [ Html.App.map ImageSearchMsg
                (ImageSearch.view model.imageSearch)
            ]
        , hr [] []
        , text <| toString model
        ]


subscriptions model =
    case model.dragState of
        Just _ ->
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
