try
% --- Setup ---
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
upKey    = KbName('UpArrow');
downKey  = KbName('DownArrow');

%% -------- WORDS (YOUR RANDOMIZATION) --------
Positions = {'Left_ear','Left_middle','left_lateral','left_pupil',...
             'left_medial','ZOC','Right_ear','Right_middle',...
             'Right_lateral','Right_pupil','Right_medial'};

PositionRepeat = repmat(Positions,1,10);
PositionRepeat = PositionRepeat(randperm(length(PositionRepeat)));

nTrials = length(PositionRepeat);

%% -------- SENTENCES (SEQUENTIAL ORDER) --------
% trial 1 -> sentence 1
% trial 2 -> sentence 2 etc
%% -------- Create sentences --------
Sentences = {

'I enjoy learning new things.'
'I like staying active.'
'I prefer simple routines.'
'I like being organized.'
'I enjoy working independently.'
'I’m curious about how things work.'
'I like planning ahead.'
'I enjoy problem-solving.'
'I’m fairly detail-oriented.'
'I like trying new experiences.'

'I enjoy reading in my free time.'
'I like watching documentaries.'
'I enjoy listening to podcasts.'
'I like learning from videos.'
'I enjoy casual gaming.'
'I like exploring new music.'
'I enjoy photography.'
'I like drawing or sketching.'
'I enjoy writing short notes.'
'I like learning new skills.'

'I enjoy going to the gym.'
'I like strength training.'
'I enjoy walking outdoors.'
'I like keeping active.'
'I enjoy tracking my progress.'
'I like stretching regularly.'
'I enjoy learning about fitness.'
'I like improving my form.'
'I enjoy setting small goals.'
'I like staying consistent.'

'I enjoy studying psychology.'
'I like learning about science.'
'I enjoy understanding research.'
'I like analyzing data.'
'I enjoy learning new concepts.'
'I like asking questions.'
'I enjoy finding patterns.'
'I like logical thinking.'
'I enjoy mental challenges.'
'I like reflecting on ideas.'

'I enjoy using new apps.'
'I like exploring AI tools.'
'I enjoy learning shortcuts.'
'I like improving efficiency.'
'I enjoy digital organization.'
'I like clean interfaces.'
'I enjoy automation.'
'I like experimenting with software.'
'I enjoy learning tech tips.'
'I like optimizing workflows.'

'I enjoy meaningful conversations.'
'I like small group settings.'
'I enjoy meeting new people.'
'I like exchanging ideas.'
'I enjoy teaching others.'
'I like learning from people.'
'I enjoy collaborating.'
'I like clear communication.'
'I enjoy sharing knowledge.'
'I like listening to perspectives.'
%LIES BELOW!!!!
'I like keeping things simple.'
'I enjoy noisy environments.'
'I like good tea.'
'I enjoy trying new foods.'
'I like exploring cafes.'
'I dont enjoy nature walks.'
'I like clean spaces.'
'I enjoy good lighting.'
'I like comfortable routines.'
'I enjoy calm mornings.'

'I like being late.'
'I go with the flow.'
'I like setting reminders.'
'I enjoy making lists.'
'I like small dogs.'
'I enjoy reviewing poems.'
'I like structured days.'
'I enjoy flexible planning.'
'I like tracking habits.'
'I enjoy Uno.'

'I enjoy Kpop.'
'I like trivia games.'
'I regularly do puzzles.'
'I like word games.'
'I enjoy developmental psychology.'
'I like learning Chinese.'
'I like cheese.'
'I like simple ideas.'
'I enjoy simple challenges.'
'I like repetition.'

'I’m generally closed-minded.'
'I’m fairly calm.'
'I’m quite observant.'
'I’m extraverted.'
'I’m pretty consistent.'
'I’m open to learning.'
'I’m inconsistent with routines.'
'I’m nervous about structure.'
'I’m interested in spirituality.'
'I accept the way I am.'

'I enjoy mmemonics.'
'I like convuluted explanations.'
'I enjoy algorithmic thinking.'
'I feel more than I think.'
'I enjoy tracking data.'
'I like complicating systems.'
'I enjoy calm activities.'
'I like focused work.'
'I enjoy steady progress more than rapid.'
'I like theory over practicality.'
'I enjoy organizing books.'
'I like simple designs.'
'I enjoy regimentation.'
'I like testing cars.'
'I enjoy philosophy.'
'I accept my flaws.'
'I love feedback.'
'I like filing my wins.'
'I enjoy learning different languages.'
'I live in the present.'

};

nTrials = length(Sentences);

%% -------- STORAGE --------
wordShown = cell(nTrials,1);

responseStore = zeros(nTrials,1);
RTstore = nan(nTrials,1);

readResponseStore = zeros(nTrials,1);
readRTstore = nan(nTrials,1);

missedTrials = [];

%% =====================================================
%% ---------------- MAIN TRIAL LOOP --------------------
%% =====================================================
for trial = 1:nTrials

    KbReleaseWait;

    currentWord = PositionRepeat{trial};
    currentSentence = Sentences{trial};   % <-- SEQUENTIAL pairing

    wordShown{trial} = currentWord;

    %% -------- SHOW WORD --------
    DrawFormattedText(myWindow,currentWord,'center','center',[255 255 255]);
    Screen('Flip', myWindow);

    Speak('Down'); WaitSecs(1);
    Speak('Test'); WaitSecs(1);
    Speak('Respond');

    %% -------- FIRST RESPONSE (2s) --------
    startTime = GetSecs;
    response = 0; reactionTime = NaN;

    while GetSecs-startTime < 2
        [keyIsDown, secs, keyCode] = KbCheck;

        if keyIsDown && response==0
            if keyCode(leftKey)
                response=1; reactionTime=secs-startTime;
            elseif keyCode(rightKey)
                response=2; reactionTime=secs-startTime;
            end
        end
    end

    responseStore(trial)=response;
    RTstore(trial)=reactionTime;

    if response==0
        Speak('Missed trial');
        missedTrials=[missedTrials trial];
    end

    %% -------- READ PHASE --------
    WaitSecs(1);
    Speak('Read');

    DrawFormattedText(myWindow,currentSentence,'center','center',[255 255 255]);
    Screen('Flip', myWindow);

    KbReleaseWait;

    % allow response but keep full 3s display
    startTimeRead=GetSecs;
    readResponse=0; readRT=NaN;

    while GetSecs-startTimeRead < 3
        [keyIsDown, secs, keyCode]=KbCheck;

        if keyIsDown && readResponse==0
            if keyCode(upKey)
                readResponse=1; readRT=secs-startTimeRead;
            elseif keyCode(downKey)
                readResponse=2; readRT=secs-startTimeRead;
            end
        end
    end

    readResponseStore(trial)=readResponse;
    readRTstore(trial)=readRT;

end

%% =====================================================
%% ---------------- RETRIAL MISSED ---------------------
%% =====================================================
if ~isempty(missedTrials)

    Speak('Retrials starting');

    for r=1:length(missedTrials)

        trial=missedTrials(r);
        currentWord=PositionRepeat{trial};
        currentSentence=Sentences{trial}; % same sentence as original

        KbReleaseWait;

        %% show word again
        DrawFormattedText(myWindow,currentWord,'center','center',[255 255 255]);
        Screen('Flip', myWindow);

        Speak('Down'); WaitSecs(2);
        Speak('Test'); WaitSecs(1);
        Speak('Respond');

        % response again
        startTime=GetSecs;
        response=0; reactionTime=NaN;

        while GetSecs-startTime<2
            [keyIsDown,secs,keyCode]=KbCheck;

            if keyIsDown && response==0
                if keyCode(leftKey)
                    response=1; reactionTime=secs-startTime;
                elseif keyCode(rightKey)
                    response=2; reactionTime=secs-startTime;
                end
            end
        end

        responseStore(trial)=response;
        RTstore(trial)=reactionTime;

        if response==0
            Speak('Missed trial');
        end

        %% read phase again
        WaitSecs(1);
        Speak('Read');

        DrawFormattedText(myWindow,currentSentence,'center','center',[255 255 255]);
        Screen('Flip', myWindow);

        KbReleaseWait;

        startTimeRead=GetSecs;
        readResponse=0; readRT=NaN;

        while GetSecs-startTimeRead<3
            [keyIsDown,secs,keyCode]=KbCheck;

            if keyIsDown && readResponse==0
                if keyCode(upKey)
                    readResponse=1; readRT=secs-startTimeRead;
                elseif keyCode(downKey)
                    readResponse=2; readRT=secs-startTimeRead;
                end
            end
        end

        readResponseStore(trial)=readResponse;
        readRTstore(trial)=readRT;

    end
end

%% -------- Convert responses --------
responseLabel=strings(nTrials,1);
readResponseLabel=strings(nTrials,1);

for i=1:nTrials
    if responseStore(i)==1,responseLabel(i)="YES";
    elseif responseStore(i)==2,responseLabel(i)="NO";
    else,responseLabel(i)="No Response";end

    if readResponseStore(i)==1,readResponseLabel(i)="YES";
    elseif readResponseStore(i)==2,readResponseLabel(i)="NO";
    else,readResponseLabel(i)="No Response";end
end

%% -------- Save --------
ResultsTable=table((1:nTrials)',wordShown,responseLabel,RTstore,...
    readResponseLabel,readRTstore,...
    'VariableNames',{'Trial','Word','Response','ReactionTime',...
    'ReadResponse','ReadReactionTime'});

disp(ResultsTable)
writetable(ResultsTable,'participant_dataLGBPOSTACUITYgwenliaw.csv');

Screen('CloseAll');

catch
Screen('CloseAll');
psychrethrow(psychlasterror);
end