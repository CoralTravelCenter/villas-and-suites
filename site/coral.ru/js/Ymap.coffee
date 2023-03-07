import { AppState } from './app-state.js'

export class Ymap
    constructor: (options) ->
        @options = {
            el: '#ymap'
            ymaps_api: '//api-maps.yandex.ru/2.1.64/?lang=ru_RU'
            hotels: null
            appState: null
            iconDefault: '/site/coral.ru/assets/ymap-marker-default.png'
            iconHilite: '/site/coral.ru/assets/ymap-marker-hilite.png'
            options...
        }
    init: () ->
        @hotels = @options.hotels
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

    extendHotelsData: () ->
        @hotels.forEach (hotel) =>
            hotel.placemark = new ymaps.Placemark hotel.latlng,
                balloonContentHeader: hotel.name
                balloonContentBody: "от <strong>#{ hotel.price }</strong> &#x20BD"
                hotelData: hotel
            ,
                zIndex: 0
                iconLayout: 'default#image'
                iconImageHref: '/site/coral.ru/assets/ymap-marker-default.png'
                iconImageSize: [26,32]
                iconImageOffset: [-13,-32]
            hotel.placemark.events.add 'click', (e) =>
                hotel_key = e.originalEvent.target.properties.get('hotelData').key
                @options.appState.set 'selected_hotel_key', hotel_key


    hotelByKey: (key) -> _(HOTELS_DATA).find key: key
    selectedHotel: () -> @hotelByKey @options.appState.get 'selected_hotel_key'

    ymapsInit: () ->
        console.log '*** ymapsInit'

        @extendHotelsData()

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

        @syncMapWithSelection()

    syncMapWithSelection: () ->
        selected_hotel = @selectedHotel()
        if selected_hotel.content_marker != @recent_content_marker
            @ymap.geoObjects.removeAll()
            @hotels
                .filter (hotel) => hotel.content_marker == selected_hotel.content_marker
                .forEach (hotel) => @ymap.geoObjects.add hotel.placemark
            @ymap.setBounds @ymap.geoObjects.getBounds(), duration: 1000, zoomMargin: 30
            .then =>
                @ymap.setZoom 11 if @ymap.getZoom() > 11
            @recent_content_marker = selected_hotel.content_marker
        else unless ymaps.util.bounds.containsPoint @ymap.getBounds(), selected_hotel.latlng
            @ymap.setCenter selected_hotel.latlng, @ymap.getZoom(), duration: 500
        @hiliteHotel selected_hotel

    hiliteHotel: (hotel) ->
        if @recent_hilited_hotel
            @recent_hilited_hotel.placemark.options.set 'iconImageHref', @options.iconDefault
            @recent_hilited_hotel.placemark.options.set 'zIndex', 0
            @recent_hilited_hotel.placemark.balloon.close()
        hotel.placemark.options.set 'iconImageHref', @options.iconHilite
        hotel.placemark.options.set 'zIndex', 1
        @recent_hilited_hotel = hotel

    selectionChanged: () ->
        @syncMapWithSelection()
