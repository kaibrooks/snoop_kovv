% Snoop Kovv
% Kai Brooks
% github.com/kaibrooks
% 2019
%
% Generates new Snoop Dogg song lyrics using a Markov Chain

% Init
clc
close all
clear all
format
rng('shuffle')

par="";

% user settings -----------------------------------------------------------

numParagraphs = 4;      % 'paragraphs' to generate
termChance = 0.3;       % probability a block will end early if it hits a terminator (period, etc)

mean = 36;              % mean sentence length, hard cut sentence after this many words (normal dist)
stdev = 8;              % standard deviation of sentence length

% --- output options
figureOn = 0;           % outputs state diagram
cleanup = 1;            % adjusts word and punctuation spacing for readability

% --- overlay settings
truncLength = 12;       % new line after this many words in image overlay
overlayFontSize = 48;   % size of text
overlayOpacity = 0.2;   % opacity of black background behind text

source = 1;


% -------------------------------------------------------------------------


% ---------- begin program ----------

text = getText(source);
statesText = unique(text);
states = [1:length(statesText)];

% create text index (text string as represented by state numbers)
for i = 1:length(text)
    for j = 1:length(statesText);
        if text(i) == statesText(j)
            textIndex(i) = j;
        end
    end
end

textIndex; % full text using indexed values

% temps
a = [states; statesText];
b = [textIndex; text];

% get next state
newP = zeros(length(states));
textIndex = [textIndex 0];
for i = 1:length(states)
    currentState = find(textIndex==i);         % current state
    nextState = textIndex(currentState+1);     % next state
    nextState = nonzeros(nextState);           % purge zeroes
    
    for j = 1:length(nextState)                % loop this so multiples of the same number sum correctly
        newP(i,nextState(j)) = newP(i,nextState(j))+1;
    end
end

newP;


mc = dtmc(newP, 'StateNames',statesText);
mcNorm = mc.P;

%mc.StateNames

if figureOn
    figure; graphplot(mc,'ColorNodes',true,'ColorEdges',true); saveas(gcf,'states.png'); %output
end

% text synthsis

synth = ""; % start with an empty string to concatenate to

% set which characters terminate sentences
terminator = ["!", ".", "?"];   % these elements end the line early
other = [",", "-"];             % these don't, but shouldn't be the last word in a sentence
punctuation = [terminator, other];

% create punctuation array
temp = find(ismember(text,terminator));
for i = 1:length(temp)
    termArr(i) = text(temp(i)); % this is used for appending punctuation probabalistically
end

clc % clear console before outputting text

for k=1:numParagraphs
    
    sentenceLength = ceil(normrnd(mean,stdev)); % norm distribution: (mean, stdev)
    simIndex = simulate(mc,sentenceLength);  % run markov simulation, get path
    
    % turn state paths into strings of text
    for i=1:length(simIndex)
        for j=1:length(statesText)
            if simIndex(i) == states(j)
                simText(i) = statesText(j); % associate state number with text
                break
            end
        end
        if ismember(simText(i), terminator) % stop the string creation early if we hit a terminator
            if rand() < termChance; break; end
        end
        if i == length(simIndex) % if we hit maximum words, add punctuation
            if ~ismember(simText(i), terminator) % unless the word was already a terminator
                simText(i) = strcat(simText(i), termArr(randi(length(termArr)))); % pick a probabalisticly random terminator and attach it
            end
            break
        end
    end
    
    % convert to single string for output
    s = string(strjoin(simText));
    
    % add spaces between words
    s = strcat(s, " ");
    
    if cleanup
        % clean up the string
        s = strrep(s,' ,',',');     % replace " ," with ","
        s = strrep(s,' .','.');     % replace " ." with "."
        s = strrep(s,' ?','?');     % replace " ?" with "?"
        s = strrep(s,' !','!');     % replace " !" with "!"
    end
    
    
    % capitalize first letter
    for i=1:size(s,2)
        s{i}(1)=upper(s{i}(1));
    end
    
    synth = strcat(synth, s); % add sentences together to form a single giant string
    inst(k) = s;              % individual sentences
    
    clear simText % wipe it for the next run so it doesn't concatenate again
    
end

% output text
for i = 1:length(inst)
    %fprintf("%.2i. %s\n\n",i,inst(i)) % add numbers to print like an instruction set
    fprintf("%s\n\n",inst(i))
    if i == length(inst)
        par = sprintf("%s%s",par,inst(i));
    else
        par = sprintf("%s%s\n\n",par,inst(i));
    end
end

% set up image overlay
txtOverlay = convertStringsToChars(par); % convert to a format the overlay reads
spaces = find(isspace(txtOverlay)); % vector of character position of spaces

% replace every 10th space with a newline to truncate text on image
m = 0;
for l=truncLength:truncLength:length(spaces)
    m = m+1;
    if l > length(spaces)
        break
    end
    txtOverlay(spaces(l)) = newline;
end

% generate the image
switch randi(3) % use a random background
    case 1
        I = imread('images/snoop1.jpg');
    case 2
        I = imread('images/snoop2.jpg');
    case 3
        I = imread('images/snoop3.jpg');
    otherwise
        I = imread('images/snoop1.jpg');
end

% combine background and text, display
I = imresize(I,1.4);
J = insertText(I, [1 1], txtOverlay,'FontSize',overlayFontSize,'BoxColor','black','BoxOpacity',overlayOpacity,'TextColor','white');
imshow(J);
