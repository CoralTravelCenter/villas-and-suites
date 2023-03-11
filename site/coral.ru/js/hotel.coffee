import { ASAP, fixLayout, preload, watchIntersection } from '/site/common/js/utils.coffee'

fixLayout()

ASAP ->
    $flickityReady = $.Deferred()
    $scrolltoReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/jquery-scrollTo/2.1.3/jquery.scrollTo.min.js', -> $scrolltoReady.resolve()

    $.when($scrolltoReady).done ->
        $(document).on 'click', '[data-scrollto]', ->
            $(window).scrollTo $(this).attr('data-scrollto'), 500

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