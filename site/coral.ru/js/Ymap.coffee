import { AppState } from './app-state.js'

ymapFeatureWithHotelData = (hotel, hilite=no) ->
    feature =
        type: 'Feature'
        id: hotel.key
        geometry:
            type: 'Point'
            coordinates: hotel.latlng
        properties:
            balloonContentHeader: hotel.name
            balloonContentBody: "от <strong>#{ hotel.price }</strong> &#x20BD"
            hotelData: hotel
        options:
#                    balloonLayout: @opt.balloonLayout
#                    balloonPanelLayout: @opt.panelLayout
#                    balloonPanelMaxMapArea: 700 * 500
            #balloonPanelMaxHeightRatio: 0.6
#                    iconColor: if Number(asc.IsServicePlaza) then '#0b239c' else '#3177c2'
            iconLayout: 'default#image'
            iconImageHref: ['/site/coral.ru/assets/ymap-marker-default.png','/site/coral.ru/assets/ymap-marker-hilite.png'][!!hilite * 1]
            iconImageSize: [26,32]
            iconImageOffset: [-13,-32]

objectManagerData = () ->
    omData =
        type: 'FeatureCollection'
        features: window.HOTELS_DATA.map (hotel) -> ymapFeatureWithHotelData hotel

hotelByKey = (key) -> _(HOTELS_DATA).find key: key

filterFunctionWithHotelKey = (key) ->
    hotel = hotelByKey key
    (feature_data) -> feature_data.properties.hotelData.content_marker == hotel.content_marker


export class Ymap
    constructor: (options) ->
        @options = {
            el: '#ymap'
            ymaps_api: '//api-maps.yandex.ru/2.1.64/?lang=ru_RU'
            appState: null
            options...
        }
    init: () ->
        @$ymap = $ @options.el
        ymaps_api_callback = "ymaps_loaded_#{ Math.round(Math.random() * 1000000) }"
        window[ymaps_api_callback] = () => @ymapsInit()
        $.ajax
            url: @options.ymaps_api + "&onload=#{ ymaps_api_callback }"
            dataType: 'script'
            cache: true
        .done () =>
            console.log "*** ymaps_api loaded"
        # what for wheel zoom modifier key (Alt)
        $(document).on 'keyup keydown', (e) =>
            if [18].indexOf(e.which) >= 0
                @zoom_modifier_down = e.type == 'keydown'
        @options.appState && $(@options.appState).on 'changed', => @selectionChanged()
        @
    ymapsInit: () ->
        console.log '*** ymapsInit'

        @ymap = new ymaps.Map @$ymap.get(0),
            center: [55.76, 37.64] # Москва
            zoom: 10
        @ymap.controls.remove 'searchControl'
        @$scrollZoomHint = $('.scrollzoom-hint')
        @scrollZoomTimeout = 0
        @scrollZoomUsed = false
        @ymap.events.add 'wheel', (e) =>
            if @zoom_modifier_down
                @$scrollZoomHint.removeClass 'shown'
                @scrollZoomUsed = true
            else
                e.preventDefault()
                unless @scrollZoomUsed
                    @$scrollZoomHint.addClass 'shown'
                    clearTimeout @scrollZoomTimeout
                    @scrollZoomTimeout = setTimeout () =>
                        @$scrollZoomHint.removeClass 'shown'
                    , 1000

        @ymapObjectManager = new ymaps.ObjectManager
            #syncOverlayInit: true
            clusterize: false
            clusterIconLayout: "default#pieChart"
            gridSize: 64


        @ymapObjectManager.add objectManagerData()
        if @options.appState
            @ymapObjectManager.setFilter filterFunctionWithHotelKey @options.appState.get('selected_hotel_key')
        @ymap.geoObjects.add @ymapObjectManager
        @ymap.setBounds @ymapObjectManager.getBounds(), duration: 1000, zoomMargin: 30
        .then =>
            @ymap.setZoom 11 if @ymap.getZoom() > 11
        selected_hotel_key = @options.appState.get 'selected_hotel_key'
        @hiliteHotelWithKey selected_hotel_key

#        hotel2hilite = hotelByKey selected_hotel_key
#        geoObject = @ymapObjectManager.objects.getById selected_hotel_key
#        @ymapObjectManager.remove geoObject
#        setTimeout =>
#            @ymapObjectManager.add ymapFeatureWithHotelData hotel2hilite, 'hilite'
#            @ymap.setCenter hotel2hilite.latlng, @ymap.getZoom(), duration: 1000
#        , 0
        @

    hiliteHotelWithKey: (key) ->
        if @recentlyHilitedKey
            recentGeoObject = @ymapObjectManager.objects.getById @recentlyHilitedKey
            @ymapObjectManager.remove recentGeoObject
            setTimeout =>
                @ymapObjectManager.add ymapFeatureWithHotelData hotelByKey(@recentlyHilitedKey)
            , 10
        geoObject = @ymapObjectManager.objects.getById key
        @ymapObjectManager.remove geoObject
        setTimeout =>
            @ymapObjectManager.add ymapFeatureWithHotelData hotelByKey(key), 'hilite'
            @recentlyHilitedKey = key
        , 20

    selectionChanged: () ->
        key = @options.appState.get 'selected_hotel_key'
        @hiliteHotelWithKey key
