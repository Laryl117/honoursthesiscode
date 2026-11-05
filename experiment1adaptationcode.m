% --- Setup ---
Screen('Preference','SkipSyncTests',1);
% 1. Get the screen's full dimensions
screenNumber = 0;
[screenWidth, screenHeight] = Screen('WindowSize', screenNumber);
% 2. Define your desired window size
winWidth = 1280;
winHeight = 800;
% 3. Calculate the rect to center it: [left, top, right, bottom]
baseRect = [0 0 winWidth winHeight];
centeredRect = CenterRectOnPoint(baseRect, screenWidth/2, screenHeight/2);
% 4. Open the window
myWindow = Screen('OpenWindow', screenNumber, [0 0 0], centeredRect);
Screen('TextSize', myWindow, 50);

% --- Create words ---
Positions = {'bear','cow','chicken','snake','dinosaur','monkey','blink three times!'};
% repeat each 2 times (changed from 20 for testing)
PositionRepeat = repmat(Positions, 1, 10);
% randomize order
PositionRepeat = PositionRepeat(randperm(length(PositionRepeat)));
nTrials = length(PositionRepeat);

% --- Keyboard setup ---
KbName('UnifyKeyNames');
spaceKey = KbName('space');
% Prevent keys from interfering with MATLAB
ListenChar(2);

% --- Data Logging Setup ---
% Initialize arrays for saving data
dataLog = struct(); % Use a struct to store varied data types
targetWord = 'blink three times!';

% --- Trial loop ---
for trial = 1:nTrials
    % Get current word
    currentWord = PositionRepeat{trial};
    
    % Draw word
    DrawFormattedText(myWindow, currentWord, 'center','center',[255 255 255]);
    vbl = Screen('Flip', myWindow);
    
    % --- 2 second response window ---
    startTime = GetSecs;
    pressed = 0;
    rt = NaN; % Default to NaN if no response
    
    % Clear keyboard buffer before trial
    KbReleaseWait; 
    
    while GetSecs - startTime < 3
        [keyIsDown, secs, keyCode] = KbCheck;
        if keyIsDown && keyCode(spaceKey)
            pressed = 1;
            rt = secs - startTime; % Reaction time
            break;
        end
    end
    
    % --- Store data for this trial ---
    dataLog(trial).trial = trial;
    dataLog(trial).word = currentWord;
    dataLog(trial).pressed = pressed;
    dataLog(trial).rt = rt;
    dataLog(trial).isCorrectTarget = strcmp(currentWord, targetWord);
    
    % Optional: Visual feedback (clear screen)
    Screen('Flip', myWindow);
    WaitSecs(0.5); % Inter-trial interval
end

% --- Cleanup ---
ListenChar(0); % Re-enable keyboard input to MATLAB
sca;

% --- Display Results ---
% Convert struct to table for easy viewing
resultsTable = struct2table(dataLog);
disp(resultsTable);

% Save results
save('experiment_datapalmeradaptation.csv', 'dataLog', 'resultsTable');
 