import { ASAP, fixLayout, autoplayVimeo, preload, watchIntersection } from '/site/common/js/utils.coffee'

fixLayout()

manageContent = (controls, state_true_false) ->
    $controls = $(controls)
    $controls.each (idx, el) ->
        $el = $(el)
        content_key = $el.attr 'data-content-control'
        if content_key
            $managed_content_els = $("[data-content-marker='#{ content_key }']")
            $managed_content_els.toggleClass 'shown', !!state_true_false
            manageContent $managed_content_els.add($managed_content_els.find('[data-content-control].selected, [data-content-control].is-selected')), !!state_true_false
            $managed_content_els.closest('[class*=flicker]').each (idx, slider) ->
                $slider = $(slider)
                $slider.flickity 'destroy' if $slider.hasClass 'flickity-enabled'
                $slider.flickity
                    cellSelector: '.logo-slide.shown'
                    cellAlign: 'center'
                    contain: yes
                    prevNextButtons: no
                    pageDots: no
                .on 'staticClick.flickity', (e, p, el, idx) -> $(this).flickity 'select', idx


contentMonitor = (what) ->
    mo = new MutationObserver (mlist, observer) ->
        for m in mlist
            if m.type == 'attributes'
                if m.target.classList.contains('selected') or m.target.classList.contains('is-selected')
                    manageContent m.target, yes
                else
                    manageContent m.target, no
    if what.jquery
        nodes = what.toArray()
    else if what instanceof Array
        nodes = Array.from what
    else if what instanceof Node
        nodes = [what]
    else if typeof what == 'string'
        nodes = Array.from document.querySelectorAll what
    else
        throw "*** contentMonitor: Got something unusable as 'what' param"

    for node in nodes
        mo.observe node, attributeFilter: ['class']
    mo

ASAP ->
    $flickityReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()

    contentMonitor 'section.country-select nav .item'
    contentMonitor 'section.region-select [data-content-control]'

    $(document).on 'click', 'section.region-select [data-content-control]', ->
        $(this).addClass('selected').siblings('.selected').removeClass('selected')

    $.when($flickityReady).done ->
        $slider = $('section.country-select nav')
        .flickity
            cellSelector: '.item'
            cellAlign: 'center'
            wrapAround: no
            prevNextButtons: yes
            pageDots: yes
        .on 'staticClick.flickity', (e, p, el, idx) -> $(this).flickity 'select', idx
        autoplayVimeo 'section.country-select .vimeo-player', 'data-vimeo-vid',
            threshold: 1, root: $slider.find('.flickity-viewport').get(0), rootMargin: '0px -30%'
        autoplayVimeo 'section.hotel-select .vimeo-player', 'data-vimeo-vid', threshold: .5

    watchIntersection $('section.kv').get(0), { threshold: .25 },
        -> $('.container-tabItem.activeTab.sticky').removeClass 'hidden'
        -> $('.container-tabItem.activeTab.sticky').addClass 'hidden'
