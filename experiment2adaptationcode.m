try
Screen('Preference','SkipSyncTests',1);

screenNumber = 0;
[screenWidth, screenHeight] = Screen('WindowSize', screenNumber);

winWidth = 1280;
winHeight = 800;

baseRect = [0 0 winWidth winHeight];
centeredRect = CenterRectOnPoint(baseRect, screenWidth/2, screenHeight/2);

myWindow = Screen('OpenWindow', screenNumber, [0 0 0], centeredRect);
Screen('TextSize', myWindow, 50);
    % keyboard setup 
    KbName('UnifyKeyNames');
    upKey = KbName('UpArrow');
    downKey = KbName('DownArrow');

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

    %% -------- PREALLOCATE DATA STORAGE --------
    trialNumber = (1:nTrials)';
    responseLog = zeros(nTrials,1);   % 1 = YES (UpArrow), 0 = NO (DownArrow)
    reactionTimeLog = nan(nTrials,1);

    %% -------- Trial loop --------
    for trial = 1:nTrials

        currentSentence = Sentences{trial};

        DrawFormattedText(myWindow,currentSentence,...
            'center','center',[255 255 255]);
        Screen('Flip', myWindow);

        WaitSecs(1)
        Speak('Read');
        WaitSecs(3);
        
        sentenceStart = GetSecs;
        response = 0;
        responseRT = NaN;

        Speak('Respond')

        % respond within 2 seconds 
        while GetSecs - sentenceStart < 2

            [keyIsDown, secs, keyCode] = KbCheck;

            % YES = UpArrow
            if keyIsDown && keyCode(upKey) && isnan(responseRT)
                response = 1;
                responseRT = secs - sentenceStart;
            end

            % NO = DownArrow
            if keyIsDown && keyCode(downKey) && isnan(responseRT)
                response = 0;
                responseRT = secs - sentenceStart;
            end
        end

        % -------- STORE RESULTS --------
        responseLog(trial) = response;
        reactionTimeLog(trial) = responseRT;

    end

    Screen('CloseAll');

    %% -------- CREATE TABLE --------
    resultsTable = table(trialNumber, Sentences, responseLog, reactionTimeLog,...
        'VariableNames',{'Trial','Sentence','Response','ReactionTime'});

    %% -------- DISPLAY TABLE --------
    disp(resultsTable)

    %% -------- SAVE TO FILE --------
    writetable(resultsTable,'Larylpiloting_resultsParticipant2.csv');

    disp('Results saved as Larylpiloting_resultsParticipant2.csv')

catch
    Screen('CloseAll');
    psychrethrow(psychlasterror);
end