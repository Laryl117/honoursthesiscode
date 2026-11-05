try
%% ===================== SETUP =====================
rng('shuffle');
Screen('Preference','SkipSyncTests',1);

screenNumber = 0;
[screenWidth, screenHeight] = Screen('WindowSize', screenNumber);

winWidth = 1280;
winHeight = 800;
baseRect = [0 0 winWidth winHeight];
centeredRect = CenterRectOnPoint(baseRect, screenWidth/2, screenHeight/2);

myWindow = Screen('OpenWindow', screenNumber, [0 0 0], centeredRect);
Screen('TextSize', myWindow, 50);

KbName('UnifyKeyNames');
leftKey  = KbName('LeftArrow');
rightKey = KbName('RightArrow');
spaceKey = KbName('space');

%% ===================== CREATE WORDS =====================
Positions = {'Left_ear','Left_middle','Left_lateral','Left_pupil',...
             'Left_medial','ZOC','Right_ear','Right_middle',...
             'Right_lateral','Right_pupil','Right_medial'};

PositionRepeat = repmat(Positions, 1, 10);
PositionRepeat = PositionRepeat(randperm(length(PositionRepeat)));

totalTrials = length(PositionRepeat);

% Randomly choose 10 blink trials
blinkTrials = randperm(totalTrials,10);

%% ===================== STORAGE =====================
wordShown       = {};
responseStore   = [];
RTstore         = [];
blinkTrialFlag  = [];
spacePressed    = [];

trial = 1;

%% ===================== TRIAL LOOP =====================
while trial <= length(PositionRepeat)

    currentWord = PositionRepeat{trial};
    wordShown{trial,1} = currentWord;

    % Check if this is a blink trial
    blinkTrialFlag(trial,1) = ismember(trial, blinkTrials);
    spacePressed(trial,1) = 0; % default

    %% -------- SHOW WORD --------
    DrawFormattedText(myWindow, currentWord,'center','center',[255 255 255]);
    Screen('Flip', myWindow);

    Speak('Down');
    WaitSecs(1);
    Speak('Test');
    WaitSecs(1);
    Speak('Respond');

    KbReleaseWait;

    %% -------- RESPONSE WINDOW (2s) --------
    startTime = GetSecs;
    response = 0;
    reactionTime = NaN;

    while GetSecs - startTime < 2
        [keyIsDown, secs, keyCode] = KbCheck;

        if keyIsDown
            if keyCode(leftKey)
                response = 1;
                reactionTime = secs - startTime;
                break
            elseif keyCode(rightKey)
                response = 2;
                reactionTime = secs - startTime;
                break
            end
        end
    end

    %% -------- RE-QUEUE MISSED TRIALS --------
    if response == 0
        Speak('Missed trial');
        PositionRepeat{end+1} = currentWord;

        % If it was originally blink trial, re-queue blink flag too
        if blinkTrialFlag(trial) == 1
            blinkTrials(end+1) = length(PositionRepeat);
        end
    end

    responseStore(trial,1) = response;
    RTstore(trial,1) = reactionTime;

    %% -------- STANDBY (4s fixed) --------
    Speak('Standby');
    standbyStart = GetSecs;
    while GetSecs - standbyStart < 4
    end

    %% -------- BLINK TRIAL --------
    if blinkTrialFlag(trial) == 1

        DrawFormattedText(myWindow, 'Blink three times',...
            'center','center',[255 255 255]);
        Screen('Flip', myWindow);

        KbReleaseWait;

        while 1
            [~, keyCode] = KbStrokeWait;
            if keyCode(spaceKey)
                spacePressed(trial,1) = 1;
                break
            end
        end

        KbReleaseWait;
    end

    trial = trial + 1;
end

%% ===================== FINALIZE DATA =====================
nTrials = length(responseStore);

responseLabel = strings(nTrials,1);
for i = 1:nTrials
    if responseStore(i) == 1
        responseLabel(i) = "YES";
    elseif responseStore(i) == 2
        responseLabel(i) = "NO";
    else
        responseLabel(i) = "No Response";
    end
end

ResultsTable = table((1:nTrials)', wordShown, responseLabel, RTstore,...
    blinkTrialFlag, spacePressed,...
    'VariableNames',{'Trial','Word','Response','ReactionTime',...
                     'BlinkTrial','SpacePressed'});

disp(ResultsTable)
writetable(ResultsTable,'participant_datapostacuity.csv');

Screen('CloseAll');

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end