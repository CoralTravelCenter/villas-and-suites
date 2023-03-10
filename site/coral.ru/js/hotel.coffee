import { ASAP, fixLayout, preload, watchIntersection } from '/site/common/js/utils.coffee'

fixLayout()

ASAP ->
    $flickityReady = $.Deferred()
    $scrolltoReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/jquery-scrollTo/2.1.3/jquery.scrollTo.min.js', -> $scrolltoReady.resolve()

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