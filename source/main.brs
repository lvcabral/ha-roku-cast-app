' *---------------------------------------------------------------------------------------------
' *  Roku Home Assistant Cast App (https://github.com/lvcabral/ha-roku-cast-app)
' *
' *  Copyright (c) 2022 Marcelo Lv Cabral. All Rights Reserved.
' *
' *  Licensed under the MIT License. See LICENSE in the repository root for license information.
' *---------------------------------------------------------------------------------------------
Library "v30/bslCore.brs"

function main(args)
    m.screen = createObject("roScreen", true)
    m.screen.setAlphaEnable(true)
    m.codes = bslUniversalControlEventCodes()
    m.port = createObject("roMessagePort")
    m.screen.setMessagePort(m.port)
    m.player = CreateObject("roVideoPlayer")
    m.player.SetMessagePort(m.port)
    if args.u <> invalid or args.contentId <> invalid
        playStreaming(args)
    else
        drawBackground("App started with no deep link, use Home Assistant to stream a camera or other media.")
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
            else if event.isFullResult()
                exit while
            else if event.isRequestFailed()
                info = event.getInfo()
                if invalid <> info and invalid <> info.DebugMessage
                    status = info.DebugMessage
                else
                    status = event.getMessage()
                end if
                m.player.stop()
                streaming = false
                paused = false
                drawBackground(status, true)
            end if
        end if
    end while
end function

sub drawBackground(status = "", showUrl = false)
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
    if invalid <> m.streamUrl and showUrl
        font = font_registry.GetDefaultFont(16, false, false)
        m.screen.drawText("ContentId: " + m.streamUrl, 100, m.screen.getHeight()-50, color, font)
    end if
    m.screen.SwapBuffers()
end sub

sub playStreaming(args)
    url = args.u
    if url = invalid
        url = args.contentId
    end if
    contentType = args.t
    m.screen.Clear(0)
    m.screen.SwapBuffers()

    m.streamUrl = url.decodeUri()
    content = {
        Stream: { url: url }
    }
    if contentType <> invalid and contentType = "a"
        content.StreamFormat = "mp3"
        if args.songFormat <> invalid
            content.StreamFormat = args.songFormat
        end if
        drawBackground(args.songName)
    else
        content.StreamFormat = "hls"
        if args.videoFormat <> invalid
            content.StreamFormat = args.videoFormat
        end if
    end if
    m.player.SetContentList([content])
    m.player.play()
end sub
