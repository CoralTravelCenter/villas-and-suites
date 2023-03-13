import { ASAP, fixLayout, preload, watchIntersection } from '/site/common/js/utils.coffee'

fixLayout()

ASAP ->
    $flickityReady = $.Deferred()
    $scrolltoReady = $.Deferred()
    $stickyKitReady = $.Deferred()
    preload [
        'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js'
        'https://cdnjs.cloudflare.com/ajax/libs/jquery-scrollTo/2.1.3/jquery.scrollTo.min.js'
        'https://cdnjs.cloudflare.com/ajax/libs/sticky-kit/1.1.3/sticky-kit.min.js'
    ], -> $flickityReady.resolve(); $scrolltoReady.resolve(); $stickyKitReady.resolve()

    $.when($stickyKitReady).done ->
        $('section.hotel-xnav').stick_in_parent()

    $.when($scrolltoReady).done ->
        $(document).on 'click', '[data-scrollto]', ->
            $(window).scrollTo $(this).attr('data-scrollto'), 500

    $hotel_selector = $('.hotel-selector')
    $(document).on 'click', '.hotel-selector li', ->
        $this = $(this)
        $hotel_selector.toggleClass 'open'
        if $hotel_selector.hasClass 'open'
            setTimeout (-> $this.get(0).scrollIntoView behavior: 'smooth'), 500
    $(document).on 'keyup', (e) ->
        $hotel_selector.removeClass 'open' if e.keyCode == 27
    $(document).on 'click', (e) ->
        if $hotel_selector.hasClass 'open'
            unless $.contains $hotel_selector.closest('section').get(0), e.target
                $hotel_selector.removeClass 'open'

    $.when($flickityReady).done ->
        $('.concept-slider')
        .on 'staticClick.flickity', (event, pointer, cellElement, cellIndex) -> $(this).flickity 'select', cellIndex
        .flickity
            cellSelector: '.slide'
            cellAlign: 'center'
            initialIndex: 1
            wrapAround: no
            prevNextButtons: yes
            pageDots: no
        $('.infosheets').each (idx, el) ->
            $infosheet = $(this)
            $nav_buttons = $infosheet.find('.infosheets-nav button')
            $nav_buttons.on 'click', () ->
                $this = $(this)
                $slider.flickity 'select', $this.index()
            $slider = $infosheet.find('.infosheets-slider')
            .on 'select.flickity', (e, idx) ->
                $nav_buttons.eq(idx).addClass('selected').siblings('.selected').removeClass('selected')
            .flickity
                cellSelector: '.slide'
                cellAlign: 'center'
                adaptiveHeight: yes
                wrapAround: no
                prevNextButtons: no
                pageDots: no
        setTimeout ->
            $('.flickity-enabled').flickity 'resize'
        , 100

    watchIntersection 'section.kv', { threshold: .25 },
        -> $('.container-tabItem.activeTab.sticky').removeClass 'hidden'
        -> $('.container-tabItem.activeTab.sticky').addClass 'hidden'

    $(document).on 'click', '[data-action="disclose"]', ->
        $this = $(this)
        $this.toggleClass 'open'
        $this.next()[['slideUp', 'slideDown'][$this.hasClass('open') * 1]]()

    $('.villa-showroom .nav-item').on 'click', ->
        $this = $(this)
        idx = $this.index()
        $this.addClass('selected').siblings('.selected').removeClass('selected')
        $this.closest('.villa-showroom')
            .find('.main-item').eq(idx).addClass('shown')
            .siblings('.shown').removeClass('shown')