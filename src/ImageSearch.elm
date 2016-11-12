module ImageSearch exposing (State, init, Msg, update, view)

import Html.App
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events
import Json.Decode
import Http
import Task


type State
    = State
        { results : List PixabayImage
        }


init : State
init =
    State
        { results = []
        }


type Msg
    = DoSearch
    | SearchFailure Http.Error
    | SearchSuccess PixabaySearchResponse
    | ImageSelected Image


type alias Image =
    { url : String }


type alias PixabaySearchResponse =
    { totalHits : Int
    , hits : List PixabayImage
    }


pixabaySearchResponseDecoder : Json.Decode.Decoder PixabaySearchResponse
pixabaySearchResponseDecoder =
    Json.Decode.object2 PixabaySearchResponse
        (Json.Decode.at [ "totalHits" ] Json.Decode.int)
        (Json.Decode.at [ "hits" ] (Json.Decode.list pixabayImageDecoder))


type alias PixabayImage =
    { preview : String
    , webFormat : String
    }


pixabayImageDecoder : Json.Decode.Decoder PixabayImage
pixabayImageDecoder =
    Json.Decode.object2 PixabayImage
        (Json.Decode.at [ "previewURL" ] Json.Decode.string)
        (Json.Decode.at [ "webformatURL" ] Json.Decode.string)


update : Msg -> State -> ( State, Cmd Msg, Maybe Image )
update msg (State state) =
    --    case Debug.log "msg" msg of
    case msg of
        DoSearch ->
            ( State state
            , Http.get pixabaySearchResponseDecoder "https://pixabay.com/api/?key=3743261-98abda94099b11c36b061abb1&q=yellow+flowers&image_type=photo&pretty=true"
                |> Task.perform SearchFailure SearchSuccess
            , Nothing
            )

        SearchSuccess data ->
            ( State { state | results = data.hits }
            , Cmd.none
            , Nothing
            )

        SearchFailure _ ->
            ( State state, Cmd.none, Nothing )

        ImageSelected image ->
            ( State state, Cmd.none, Just image )


view : State -> Html Msg
view (State state) =
    div []
        [ button
            [ Html.Events.onClick DoSearch
            ]
            [ text "Search" ]
        , ul [] (List.map viewImage state.results)
        ]


viewImage : PixabayImage -> Html Msg
viewImage image =
    li []
        [ img
            [ src image.preview
            , style
                [ ( "max-width", "100px" )
                , ( "max-height", "100px" )
                ]
            , Html.Events.onClick (ImageSelected { url = image.webFormat })
            ]
            []
        ]


main =
    Html.App.program
        { init = ( init, Cmd.none )
        , subscriptions = \_ -> Sub.none
        , update =
            \msg oldModel ->
                let
                    ( newModel, cmd, selectedImage ) =
                        update msg oldModel

                    _ =
                        Debug.log "selectedImage" selectedImage
                in
                    ( newModel, cmd )
        , view = view
        }
