objectManagerData = () ->
    omData =
        type: 'FeatureCollection'
        features: window.HOTELS_DATA.map (hotel) ->
            feature =
                type: 'Feature'
                id: hotel.key
                geometry:
                    type: 'Point'
                    coordinates: hotel.latlng
                properties:
                    hotelData: hotel
                options:
#                    balloonLayout: @opt.balloonLayout
#                    balloonPanelLayout: @opt.panelLayout
#                    balloonPanelMaxMapArea: 700 * 500
                    #balloonPanelMaxHeightRatio: 0.6
#                    iconColor: if Number(asc.IsServicePlaza) then '#0b239c' else '#3177c2'
                    iconLayout: 'default#image'
                    iconImageHref: '/site/coral.ru/assets/ymap-marker-default.png'
                    iconImageSize: [26,32]
                    iconImageOffset: [-13,-32]


export class Ymap
    constructor: (options) ->
        @options = {
            el: '#ymap'
            ymaps_api: '//api-maps.yandex.ru/2.1.64/?lang=ru_RU'
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
            clusterize: true
            clusterIconLayout: "default#pieChart"
            gridSize: 64

        @ymapObjectManager.add objectManagerData()
        @ymap.geoObjects.add @ymapObjectManager

        @


