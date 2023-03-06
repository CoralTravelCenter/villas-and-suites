import { ASAP, fixLayout, autoplayVimeo, preload, watchIntersection, arrayOfNodesWith, queryParam } from '/site/common/js/utils.coffee'
import { AppState } from './app-state.js'
import { Ymap } from './Ymap.coffee'

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
                .on 'select.flickity', (e, idx) -> scrollToPageIdx '.videos-comp', idx


contentMonitor = (what) ->
    mo = new MutationObserver (mlist, observer) ->
        for m in mlist
            if m.type == 'attributes'
                if m.target.classList.contains('selected') or m.target.classList.contains('is-selected')
                    manageContent m.target, yes
                else
                    manageContent m.target, no
    for node in arrayOfNodesWith what
        mo.observe node, attributeFilter: ['class']
    mo

syncScroll = (source, follower, flickity) ->
    timeout = null
    $source = $(source)
    source = $source.get(0)
    $follower = $(follower)
    follower = $follower.get(0)
    $flickity = $(flickity) if flickity
    source.addEventListener 'scroll', (e) ->
        clearTimeout timeout
        timeout = setTimeout ->
            source_scroll_axis = $source.css('overflow').split(' ').indexOf('auto')
            source_scroll_pos = ['scrollLeft','scrollTop'][source_scroll_axis]
            source_el_dim = ['clientWidth','clientHeight'][source_scroll_axis]
            source_page_idx = Math.round source[source_scroll_pos] / source[source_el_dim]
            follower_scroll_axis = $follower.css('overflow').split(' ').indexOf('auto')
            follower_scroll_prop = ['left','top'][follower_scroll_axis]
            follower_el_dim = ['clientWidth','clientHeight'][follower_scroll_axis]
            scroll_opt = behavior: 'smooth'
            scroll_opt[follower_scroll_prop] = follower[follower_el_dim] * source_page_idx
            $follower.get(0).scroll scroll_opt
            $flickity?.flickity 'select', source_page_idx
        , 200

scrollProgressIndicator = (scrollable, progress_indicator) ->
    $scrollable = $(scrollable)
    scrollable_el = $scrollable.get(0)
    $progress_indicator = $(progress_indicator)
    $indicator = $(progress_indicator).find('.indicator')
    handler = () ->
        scroll_axis = $scrollable.css('overflow').split(' ').indexOf('auto')
        scroll_pos = ['scrollLeft','scrollTop'][scroll_axis]
        scroll_dim = ['scrollWidth','scrollHeight'][scroll_axis]
        el_dim = ['clientWidth','clientHeight'][scroll_axis]
        indicator_dim_set = ['width','height'][scroll_axis]
        indicator_dim_auto = ['height','width'][scroll_axis]
        indicator_anchor_set = ['bottom','top'][scroll_axis]
        indicator_anchor_auto = ['top','bottom'][scroll_axis]
        indicator_shift_set = ['left', 'top'][scroll_axis]
        indicator_shift_auto = ['top', 'left'][scroll_axis]
        op = ['hide', 'show'][(scrollable_el[scroll_dim] > scrollable_el[el_dim]) * 1]
        $progress_indicator[op]()
        $progress_indicator.css indicator_anchor_set, 0
        $progress_indicator.css indicator_anchor_auto, 'auto'
        $progress_indicator.css indicator_dim_set, '100%'
        $progress_indicator.css indicator_dim_auto, '4px'
        $indicator.css indicator_dim_set, scrollable_el[el_dim] / scrollable_el[scroll_dim] * 100 + '%'
        $indicator.css indicator_dim_auto, '100%'
        $indicator.css indicator_shift_set, scrollable_el[scroll_pos] / scrollable_el[scroll_dim] * 100 + '%'
        $indicator.css indicator_shift_auto, 0
    $scrollable.on 'scroll', handler
    mo = new MutationObserver handler
    mo.observe scrollable_el, { subtree: yes, attributeFilter: ['class'] }

scrollToPageIdx = (el_or_selector, idx) ->
    $el = $(el_or_selector)
    el = $el.get(0)
    scroll_axis = $el.css('overflow').split(' ').indexOf('auto')
    scroll_prop = ['left','top'][scroll_axis]
    el_dim = ['clientWidth','clientHeight'][scroll_axis]
    scroll_opt = behavior: 'smooth'
    scroll_opt[scroll_prop] = el[el_dim] * idx
    el.scroll scroll_opt


ASAP ->
    ymap = null
    $flickityReady = $.Deferred()
    preload 'https://cdnjs.cloudflare.com/ajax/libs/flickity/2.3.0/flickity.pkgd.min.js', -> $flickityReady.resolve()

    contentMonitor 'section.country-select nav .item'
    contentMonitor 'section.region-select [data-content-control]'

    $(document).on 'click', 'section.region-select [data-content-control]', ->
        $(this).addClass('selected').siblings('.selected').removeClass('selected')

    preselect_hotel_key = queryParam 'hotel'
    preselect_hotel = preselect_hotel_key and _(HOTELS_DATA).find(key: preselect_hotel_key) or _(HOTELS_DATA).find('default') or HOTELS_DATA[0]
    console.log "=== preselecting: %o", preselect_hotel

    window.app_state = app_state = new AppState selected_hotel_key: preselect_hotel.key

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
        autoplayVimeo 'section.hotel-select .vimeo-player', 'data-vimeo-vid', threshold: .25

    watchIntersection 'section.kv', { threshold: .25 },
        -> $('.container-tabItem.activeTab.sticky').removeClass 'hidden'
        -> $('.container-tabItem.activeTab.sticky').addClass 'hidden'

    watchIntersection '.descriptions .hotel-card', { threshold: .5, root: $('.descriptions').get(0) },
        -> this.classList.add 'in-view'
        -> this.classList.remove 'in-view'

    syncScroll '.descriptions', '.videos-comp', '.logo-nav-flicker'
    syncScroll '.videos-comp', '.descriptions', '.logo-nav-flicker'
    scrollProgressIndicator '.descriptions', '.descriptions-comp .progress-indicator'

    $(document).on 'click', '[data-action=ymap-toggle]', ->
        $('[data-action=ymap-toggle]').toggleClass 'active'
        $('.ymap-comp').toggleClass 'open'
        window.ymap = ymap = new Ymap().init() unless ymap