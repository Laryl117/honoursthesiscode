try
% --- Setup --- 
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

%% -------- Create words --------
Positions = {'Left_ear','Left_middle','left_lateral','left_pupil',...
             'left_medial','ZOC','Right_ear','Right_middle',...
             'Right_lateral','Right_pupil','Right_medial'};

PositionRepeat = repmat(Positions, 1, 10);
PositionRepeat = PositionRepeat(randperm(length(PositionRepeat)));

%% -------- CREATE STORAGE (DYNAMIC) --------
wordShown      = {};
responseStore  = [];
RTstore        = [];

%% -------- Trial loop (RE-LOOP ENABLED) --------
trial = 1;

while trial <= length(PositionRepeat)

    currentWord = PositionRepeat{trial};
    wordShown{trial,1} = currentWord;

    % draw word
    DrawFormattedText(myWindow, currentWord,'center','center',[255 255 255]);
    Screen('Flip', myWindow);

    WaitSecs(2);

    Speak('Test');
    WaitSecs(1);
    Speak('Respond');
   

    %% -------- RESPONSE WINDOW --------
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
            end
            if keyCode(rightKey)
                response = 2;
                reactionTime = secs - startTime;
                break
            end
        end
    end

    %% -------- If Missed: Beep + Re-queue --------
    if response == 0
        Speak('Missed');   % simple audible feedback
        PositionRepeat{end+1} = currentWord;   % append to END
    end

    % STORE RESPONSE + RT
    responseStore(trial,1) = response;
    RTstore(trial,1) = reactionTime;

    trial = trial + 1;
end

%% -------- Convert numeric response to labels --------
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

%% -------- Create table --------
ResultsTable = table((1:nTrials)', wordShown, responseLabel, RTstore,...
    'VariableNames',{'Trial','Word','Response','ReactionTime'});

disp(ResultsTable)
writetable(ResultsTable,'participant_gwenacuity.csv');
%remember to change for each participant!
Screen('CloseAll');

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end