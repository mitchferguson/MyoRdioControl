scriptId = 'com.mitch.rdioControl'

function playpause()
    myo.keyboard("space", "press")
end

function Forward()
    myo.keyboard("right_arrow", "press")
end

function Backward()
    myo.keyboard("left_arrow", "press")
end

function volUp()
    myo.keyboard("up_arrow","down", "command")
end

function volDown()
    myo.keyboard("down_arrow","down", "command")
end

function resetFist()
    fistMade = false
    referenceRoll = myo.getRoll()
    currentRoll = referenceRoll
    myo.keyboard("up_arrow","up", "command")
    myo.keyboard("down_arrow","up", "command")
end

-- Makes use of myo.getArm() to swap wave out and wave in when the armband is being worn on
-- the left arm. This allows us to treat wave out as wave right and wave in as wave
-- left for consistent direction. The function has no effect on other poses.
function conditionallySwapWave(pose)
    if myo.getArm() == "left" then
        if pose == "waveIn" then
            pose = "waveOut"
        elseif pose == "waveOut" then
            pose = "waveIn"
        end
    end
    return pose
end

function unlock()
    unlocked = true
    extendUnlock()
end

function lock()
    unlocked = false
end

function extendUnlock()
    unlockedSince = myo.getTimeMilliseconds()
end

-- All timeouts in milliseconds
UNLOCKED_TIMEOUT = 3000               -- Time since last activity before we lock

function onPoseEdge(pose, edge)

    if pose == "thumbToPinky" then
        if edge == "off" then
            -- Unlock when pose is released in case the user holds it for a while.
            unlock()
        end
    end
    
    if pose == "waveIn" or pose == "waveOut" or pose == "fist" or pose == "fingersSpread" then
        local now = myo.getTimeMilliseconds()

        if unlocked and edge == "on" then
            -- Deal with direction and arm.
            pose = conditionallySwapWave(pose)

            -- Determine direction based on the pose.
            if pose == "waveIn" then
                Backward()
            
            
            elseif pose == "fingersSpread" and edge == "on" then
                playpause()
                lock()
            
            
            elseif pose == "fist" then -- Sets up fist movement
                
                if not fistMade then
                    referenceRoll = myo.getRoll()
                    fistMade = true
                    if myo.getXDirection() == "towardElbow" then -- Adjusts for Myo orientation
                        referenceRoll = referenceRoll * -1
                    end
                end

            elseif pose == "waveOut" then
                Forward()
            end

            if not pose == "fist" and edge == "on" then -- Reset call
                fistMade = false
                resetFist()
            end

            -- Initial burst and vibrate
            myo.vibrate("short")
            extendUnlock()
            
        end
    end
    
    if not (pose == "fist" and edge == "on") then
        resetFist()
    end
end

function onPeriodic()
    local now = myo.getTimeMilliseconds()

    -- ...

    -- Lock after inactivity
    if unlocked then
        -- If we've been unlocked longer than the timeout period, lock.
        -- Activity will update unlockedSince, see extendUnlock() above.
        if (now - unlockedSince) > UNLOCKED_TIMEOUT then
            unlocked = false
            myo.vibrate("short")
        end
    end

    currentRoll = myo.getRoll()
    if myo.getXDirection() == "towardElbow" then
        currentRoll = currentRoll * -1
        extendUnlock()
    end

    if unlocked and fistMade then -- Moves page when fist is held and Myo is rotated
        extendUnlock()
        subtractive = currentRoll - referenceRoll
        if subtractive > 0.3  then
            volUp()
        elseif subtractive < -0.3 then
            volDown() 
        end
    end

end


function onForegroundWindowChange(app, title)
    local wantActive = false
    activeApp = ""

    if platform == "MacOS" then
        if app == "com.rdio.desktop" then
            -- Rdio on MacOS
            wantActive = true
            activeApp = "Rdio"
        
        end
        elseif platform == "Windows" then
        -- Rdio on Windows
        wantActive = string.match(title, "Rdio")
        activeApp = "Rdio"

    end
    return wantActive
end

function activeAppName()
    -- Return the active app name determined in onForegroundWindowChange
    return activeApp
end

function onActiveChange(isActive)
    if not isActive then
        myo.vibrate("short")
        unlocked = false
    elseif isActive then
        myo.vibrate("short")
        myo.vibrate("short")
    end
end
