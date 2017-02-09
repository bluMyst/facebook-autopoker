console.clear()
console.log "Ready to poke back."

class LocalStorageValue
    constructor: (@name, @defaultValue) ->
        if not @getValue()?
            @setValue @defaultValue

    getValue: -> localStorage.getItem @name
    setValue: (value) -> localStorage.setItem @name, value

class AutoPokeSettings
    DEFAULT_AUTO_POKE: true
    DEFAULT_MIN_DELAY:  5000
    DEFAULT_MAX_DELAY: 60000

    # For highlighting a textbox red when the user enters the wrong thing.
    TEXTBOX_INVALID_STYLE: "border-color: red;"

    constructor: (autoInject=true) ->
        ###
        # If autoInject is true, we'll automatically injectHTML()
        ###
        @autoPoke = new LocalStorageValue "fbap_autoPoke", @DEFAULT_AUTO_POKE
        @minDelay = new LocalStorageValue "fbap_minDelay", @DEFAULT_MIN_DELAY
        @maxDelay = new LocalStorageValue "fbap_maxDelay", @DEFAULT_MAX_DELAY

        @buildSettingsDiv()
        @addListeners()

        if autoInject
            @injectHTML()

    injectHTML: ->
        mainDiv = document.querySelector("#contentArea > div")

        mainDiv.insertBefore(@settingsDiv, mainDiv.firstChild)

    cleanup: ->
        @settingsDiv.remove()

    buildSettingsDiv: ->
        @settingsDiv = document.createElement 'div'
        @settingsDiv.id = 'settingsDiv'

        @settingsDiv.innerHTML = """
            <div class="_4-u2 _xct _4-u8">
                <div class='uiHeader'>
                    <h2 class=uiHeaderTitle>
                        Auto-Poker Settings
                    </h2>

                    <label>
                        <input type=checkbox id=autoPoke>
                        Auto-Poke
                    </label><br/><br/>

                    <label>
                        Min click delay (seconds): <input type=text id=minDelay>
                    </label><br/><br/>

                    <label>
                        Max click delay (seconds): <input type=text id=maxDelay>
                    </label><br/>
                </div>
            </div>
        """

        @autoPokeNode = @settingsDiv.querySelector "#autoPoke"
        @minDelayNode = @settingsDiv.querySelector "#minDelay"
        @maxDelayNode = @settingsDiv.querySelector "#maxDelay"

        @autoPokeNode.checked = @autoPoke.getValue()
        @minDelayNode.value   = (@minDelay.getValue() / 1000).toString()
        @maxDelayNode.value   = (@maxDelay.getValue() / 1000).toString()

    addListeners: ->
        @autoPokeNode.addEventListener "click", (mouseEvent) =>
            @autoPoke.setValue @autoPokeNode.checked
            console.log "autoPoke:", @autoPoke.getValue()

        @minDelayNode.addEventListener "input", (event) =>
            input = (Number @minDelayNode.value) * 1000

            if isNaN(input)
                @minDelayNode.style = @TEXTBOX_INVALID_STYLE
            else if input > @maxDelay.getValue()
                @maxDelayNode.style = @TEXTBOX_INVALID_STYLE
            else
                @maxDelayNode.style = ""
                @minDelayNode.style = ""
                @minDelay.setValue input
                console.log "minDelay:", @minDelay.getValue()

        @maxDelayNode.addEventListener "input", (event) =>
            input = (Number @maxDelayNode.value) * 1000

            if isNaN(input)
                @maxDelayNode.style = @TEXTBOX_INVALID_STYLE
            else if input < @minDelay.getValue()
                @minDelayNode.style = @TEXTBOX_INVALID_STYLE
            else
                @maxDelayNode.style = ""
                @minDelayNode.style = ""
                @maxDelay.setValue input
                console.log "maxDelay:", @maxDelay.getValue()

setTimeout_ = (time, f) -> setTimeout f, time

getRandomInt = (min, max) ->
  min = Math.ceil(min)
  max = Math.floor(max)
  return Math.floor(Math.random() * (max - min + 1)) + min

clicks = 0
settings = new AutoPokeSettings()

observer = new MutationObserver (mutationRecords, mutationObserver) ->
    if settings.autoPoke.getValue()
        for record in mutationRecords
            for node in record.addedNodes
                if node.id?.startsWith 'poke_live_item_'
                    console.groupCollapsed "Found pokable person."

                    button = node.querySelector('a[ajaxify^="/pokes/inline/?"]:not([title])')
                    console.log "node:", node
                    console.log "button:", button

                    waitTime = getRandomInt(
                        settings.minDelay.getValue(),
                        settings.maxDelay.getValue())

                    console.log "waiting #{waitTime/1000} seconds."

                    setTimeout_ waitTime, ->
                        clicks++
                        console.log "click number:", clicks

                        button.click()
                        console.groupEnd()

# Because $ is broken on Facebook fsr.
pokesContainer = document.querySelector('#poke_live_new').parentElement

observer.observe pokesContainer,
    childList: true
    subtree: true
