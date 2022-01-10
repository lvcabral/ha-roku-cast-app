' ******
' ****** Home Assistant Stream Channel
' ******
Library "v30/bslCore.brs"

function main(args)
    m.screen = createObject("roScreen", true)
    m.screen.setAlphaEnable(true)
    m.codes = bslUniversalControlEventCodes()
    m.port = createObject("roMessagePort")
    m.screen.setMessagePort(m.port)
    m.player = CreateObject("roVideoPlayer")
    m.player.SetMessagePort(m.port)
    if invalid <> args.contentId
        playStreaming(args.contentId)
    else
        drawBackground("App started with no deep link, use HA Roku custom component to stream a camera or other media.")
    end if
    streaming = false
    paused = false
    while true
        event = wait(0, m.port)
        if type(event) = "roUniversalControlEvent"
            button = event.getInt()
            if button = m.codes.button_play_pressed
                if not paused
                    m.player.pause()
                else
                    m.player.resume()
                end if
            else if button = m.codes.button_back_pressed
                if streaming
                    m.player.stop()
                end if
                exit while
            end if
        else if type(event) = "roVideoPlayerEvent"
            if event.isStreamStarted()
                streaming = true
            else if event.isPaused()
                paused = true
            else if event.isResumed()
                paused = false
            else if event.isFullResult() or event.isRequestFailed()
                info = event.getInfo()
                if invalid <> info and invalid <> info.DebugMessage
                    status = info.DebugMessage
                else
                    status = event.getMessage()
                end if
                m.player.stop()
                streaming = false
                paused = false
                drawBackground(status)
            end if
        end if
    end while
end function

sub drawBackground(status = "")
    m.screen.Clear(0)
    m.screen.SwapBuffers()
    bmp = CreateObject("roBitmap", "pkg:/images/ha-background.png")
    width = bmp.getWidth()
    if width <> m.screen.getWidth()
        scale = m.screen.getWidth() / width
        m.screen.DrawScaledObject(0, 0, scale, scale, bmp)
    else
        m.screen.DrawObject(0, 0, bmp)
    end if
    color = &hFFFFFFFF
    font_registry = CreateObject("roFontRegistry")
    if "" <> status
        font = font_registry.GetDefaultFont(24, false, false)
        m.screen.drawText(status, 100, m.screen.getHeight()-100, color, font)
    end if
    if invalid <> m.streamUrl
        font = font_registry.GetDefaultFont(16, false, false)
        m.screen.drawText("ContentId: " + m.streamUrl, 100, m.screen.getHeight()-50, color, font)
    end if
    m.screen.SwapBuffers()
end sub

sub playStreaming(contentId)
    if invalid <> contentId
        m.streamUrl = contentId.decodeUri()
        content = {
            Stream: { url: m.streamUrl }
        }
        if m.streamUrl.right(5) = ".m3u8"
            content.StreamFormat = "hls"
        end if
        m.screen.Clear(0)
        m.screen.SwapBuffers()
        m.player.SetContentList([content])
        m.player.play()
    end if
end sub
