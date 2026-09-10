function ptb = PTBSettings(SetUp, useEyetracker, stereomodeSequential)
%PTBSettings: reads out and sets values from/for Psychtoolbox and the
%experiment
%   input:
%       SetUp - where the experiment is running currently
%   The function opens a window, and assigns keys to specific tasks (e.g.,
%   accept), sets colors, fonts etc.
if nargin < 1 || isempty(SetUp)
    SetUp = 'CIN-experimentroom';
end
% Decide which set up to use
ptb.SetUp = SetUp;

% Turn initial start screen from white to black
Screen('Preference', 'VisualDebugLevel', 1);

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Set a new random seed.
ptb.seed = rng('shuffle');

%............................. KEYS ......................................%
% ListenChar(2);

% Keyboard pre-setup
% KbName('UnifyKeyNames'); % not needed if PsychDefaultSetup is called with a feature level >0
ptb.KeyList1 = zeros (256, 1); % initiate an empty array that later, when keys are defined, is filled with the allowed keys
ptb.KeyList2 = zeros (256, 1); % initiate an empty array that later, when keys are defined, is filled with the allowed keys
ptb.usbTrg = 1; % If 1 --> wait for scanner triggers & check USB inputs.

% general keys independent of the setup
ptb.Keys.escape = KbName('ESCAPE');     ptb.KeyList1(ptb.Keys.escape)= double(1);
ptb.Keys.yes    = KbName('y');          ptb.KeyList1(ptb.Keys.yes)   = double(1);
ptb.Keys.no     = KbName('n');          ptb.KeyList1(ptb.Keys.no)    = double(1);
ptb.Keys.debug  = 1;
if stereomodeSequential
    ptb.steremode = 1; % == sequential for BR + shutter glasses
    ptb.usedatapixx = true;
else
    ptb.stereomode = 4; % == side by side for BR
    ptb.usedatapixx = false;
end

switch ptb.SetUp
    case 'CIN-personal'
        % subject keys
        ptb.Keys.left   = KbName('LeftArrow');  ptb.KeyList2(ptb.Keys.left)  = double(1);
        ptb.Keys.right  = KbName('RightArrow'); ptb.KeyList2(ptb.Keys.right) = double(1);
        ptb.Keys.up     = KbName('UpArrow');    ptb.KeyList2(ptb.Keys.left)  = double(1);
        ptb.Keys.down   = KbName('DownArrow');  ptb.KeyList2(ptb.Keys.right) = double(1);
        ptb.Keys.accept = KbName('Space');      ptb.KeyList2(ptb.Keys.accept)= double(1);
        % Get Keyboard indices
        [keyboardIndices, productNames, ~] = GetKeyboardIndices('Tastatur');
        % for some reason GetKeyboardIndices returns two indices
        % for the Keyboard. The physical device might offer several
        % interfaces to interact with it
        % It looks like the first index is the one working
        % However, apparently on tuxedo os and windows it looks like 
        % assigning keyboardIndices(1)to both ptb keyboards does not work.
        % It helps in this case to allow them to use different interfaces
        % provided by the same device
        ptb.Keyboard1 = keyboardIndices(1);
        ptb.Keyboard2 = keyboardIndices(1); % (change back to 1 if this doesnt work)
        fprintf('\n=> Subjects keyboard Nr.: %u  %s \n',ptb.Keyboard2, productNames{1});
        fprintf('\n=> Experimenter keyboard Nr.: %u  %s \n',ptb.Keyboard2, productNames{1});

    case 'CIN-experimentroom'
        % subject keys
        ptb.Keys.left   = KbName('4');  ptb.KeyList2(ptb.Keys.left)  = double(1);
        ptb.Keys.right  = KbName('6');  ptb.KeyList2(ptb.Keys.right) = double(1);
        ptb.Keys.up     = KbName('8');  ptb.KeyList2(ptb.Keys.left)  = double(1);
        ptb.Keys.down   = KbName('2');  ptb.KeyList2(ptb.Keys.right) = double(1);
        ptb.Keys.accept = KbName('5');  ptb.KeyList2(ptb.Keys.accept)= double(1);
        % Get Keyboard indices
        [keyboardIndicesExp, productNamesExp, ~] = GetKeyboardIndices('Apple Inc. Apple Keyboard');
        [keyboardIndicesSub, productNamesSub, ~] = GetKeyboardIndices('HID 04d9:1203');
        ptb.Keyboard1 = keyboardIndicesExp(1);
        ptb.Keyboard2 = keyboardIndicesSub(1);
        fprintf('\n=> Subjects keyboard Nr.: %u  %s \n',ptb.Keyboard2, productNamesExp{1});
        fprintf('\n=> Experimenter keyboard Nr.: %u  %s \n',ptb.Keyboard2, productNamesSub{1});
    case 'MPI'
        ptb.usedatapixx = true;
        % Because of the MR compatible keyboard we flip the order of button
        % presses. Additionally the buttons for the binary answers are index
        % (button 4$) and middle finger (button 3#)
        % The KeyList must be filled with doubles
        ptb.Keys.trg    = KbName ('w');     ptb.KeyList2(ptb.Keys.trg)   = double(1); % The scanner sends 'w' as USB keyboard input (from keyboard 2)
        ptb.Keys.left   = KbName('4$');  ptb.KeyList2(ptb.Keys.left)  = double(1);
        ptb.Keys.right  = KbName('3#'); ptb.KeyList2(ptb.Keys.right) = double(1);
        ptb.Keys.up     = KbName('UpArrow');    ptb.KeyList2(ptb.Keys.left)  = double(1);
        ptb.Keys.down   = KbName('DownArrow');  ptb.KeyList2(ptb.Keys.right) = double(1);
        ptb.Keys.accept = KbName('5%');     ptb.KeyList2(ptb.Keys.accept)= double(1);

        [keyboardIndicesSub, productNamesSub, ~] = GetKeyboardIndices('P.I. Engineering Xkeys');
        ptb.Keyboard2  = keyboardIndicesSub(1);
        fprintf('\n=> Subjects keyboard Nr.: %u  %s \n',ptb.Keyboard2, productNamesSub{1});
        
        [keyboardIndicesExp, productNamesExp, ~] = GetKeyboardIndices('Dell Dell USB Entry Keyboard');
        ptb.Keyboard1  = keyboardIndicesExp(1);
        fprintf('\n=> Experimentators keyboard Nr.: %u  %s \n',ptb.Keyboard1, productNamesExp{1});
    otherwise
        error('No proper Set up was selected');
end

if ptb.Keyboard1 == ptb.Keyboard2
   warning('You are using only one keyboard!'); 
end

% create & start KbQueue for the first Keyboard.
KbQueueCreate(ptb.Keyboard1, ptb.KeyList1);
KbQueueStart(ptb.Keyboard1);

% create & start KbQueue for the second Keyboard.
KbQueueCreate(ptb.Keyboard2, ptb.KeyList2);
KbQueueStart(ptb.Keyboard2);
%........................... END KEYS ....................................%

%% ---------------------- EYETRACKER ----------------------------------- %
ptb.useEyetracker = useEyetracker; % stupid default
if ptb.useEyetracker % If ET, then make calibration
    ptb.eyelink.track       = 1; % 0 - no tracking, -1 - dummymode
    ptb.key.sendToEyelink   = 1; % Send keypress to EyeLink-datafile, only if eyetracker is connected
    %unix('xrandr --screen 1 --output DP-0 --mode 1920x1080 --rate 60'); % we change the resolution using unix command xrandr to 60 hz. IMPORTANT: ONLY WORKS IF ProPixx is DP-0 and screen 1!!
    %ptb = startEyetracker(ptb, data);
    %Screen('Close', ptb.et.window);
    %unix('xrandr --screen 1 --output DP-0 --mode 1920x1080 --rate 120'); % reset resolution and set back to 120 hz suing unix command xrandr
else % Do nothing
    ptb.eyelink.track       = 0; % 0 - no tracking, -1 - dummymode
    ptb.key.sendToEyelink   = 0; % Send keypress to EyeLink-datafile, only if eyetracker is connected
    %unix('xrandr --screen 1 --output DP-0 --mode 1920x1080 --rate 120'); % LM3 hotfix
end
%-------------------------------------------------------------------------%
PsychImaging('PrepareConfiguration');                                     % standard first command
% PsychImaging('AddTask', 'General', 'SideBySideCompressedStereo');       % not quite sure I need it
% PsychImaging('AddTask', 'General', 'UseVirtualFramebuffer');            % nice to have - not necessary, but suggested
% PsychImaging('AddTask', 'General', 'UseFineGrainedTiming', 'Auto');     % makes timing even more efficient, but if the hardware does not support it, PsychImaging('OpenWindow') fails
% PsychImaging('AddTask', 'General', 'UseFastOffscreenWindows');          % accelerates switching between drawing into onscreen and offscreen windows

%% -------------------Shutter Glasses ------------------------------------%
if ptb.usedatapixx
    % Tell PTB we want to display on a DataPixx device:
    PsychImaging('AddTask', 'General', 'UseDataPixx');

    % Enable DATAPixx blueline support
    Datapixx('Open');
    Datapixx('EnableVideoStereoBlueline');
    Datapixx('SetVideoStereoVesaWaveform', 5);      % If driving VOLFONI (5), NVIDIA (2) glasses
    fprintf("Successfully opened DataPixx!")
    if Datapixx('IsViewpixx3D')
        Datapixx('EnableVideoLcd3D60Hz');
    end
    Datapixx('RegWr');
end
%.......................... Window Configuration .........................%
% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer.
ptb.screens = Screen('Screens');

% To draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen.
ptb.screenNumber = max(ptb.screens);

% Define black and white (white will be 1 and black 0). This is because
% in general luminace values are defined between 0 and 1 with 255 steps in
% between. All values in Psychtoolbox are defined between 0 and 1
ptb.white = WhiteIndex(ptb.screenNumber);
ptb.black = BlackIndex(ptb.screenNumber);

% Do a simply calculation to calculate the luminance value for grey. This
% will be half     the luminace values for white
ptb.grey = ptb.white / 2;

% general screen settings
ptb.FontColor = ptb.black;
ptb.BackgroundColor = ptb.grey; %TODO 

switch ptb.SetUp
    case 'CIN-personal'
        [ptb.window, ptb.windowRect] = PsychImaging('OpenWindow', ptb.screenNumber, ptb.BackgroundColor, [0 0 1920 1200], [],[],ptb.stereomode); 
        % Real world variable
        ptb.DistToMonitor   = 570;  % Distance to monitor in mm (measured by hand) - REMEASURE
        ptb.widthMonitor    = 180;  % monitor width measured by hand - REMEASURE
        ptb.heightMonitor   = 120;  % monitor height measured by hand - REMEASURE
        ptb.lineWidthInPix  = 4;    % line width in pixels for fixation cross

    case 'CIN-experimentroom'
        [ptb.window, ptb.windowRect] = PsychImaging('OpenWindow', ptb.screenNumber, ptb.BackgroundColor, [], [],[],ptb.stereomode);      
        ptb.FontSize = Screen('TextSize', ptb.window, 25);

        % Real world variable
        ptb.DistToMonitor   = 560;  % Distance to monitor in mm 
        ptb.widthMonitor    = 600;  % monitor width 
        ptb.heightMonitor   = 340;  % monitor height
        ptb.lineWidthInPix  = 4;    % line width in pixels for fixation cross
    case 'MPI'
        [ptb.window, ptb.windowRect] = PsychImaging('OpenWindow', ptb.screenNumber, ptb.BackgroundColor, [], [],[],ptb.stereomode);    
        ptb.FontSize = Screen('TextSize', ptb.window, 40);

        % Real world variable
        ptb.DistToMonitor   = 1050;  % Distance to monitor in mm (measured by hand) - REMEASURE
        ptb.widthMonitor    = 470;  % monitor width measured by hand - REMEASURE
        ptb.heightMonitor   = 265;  % monitor height measured by hand - REMEASURE
        ptb.lineWidthInPix  = 4;    % line width in pixels for fixation cross
    otherwise
        error('No proper Set up was selected');
end

%constants for better readability when addressing left and right buffer
ptb.leftBuffer = 0;
ptb.rightBuffer = 1;

% Get the size of the on screen window in pixels, these are the last two
% numbers in "windowRect" and "rect"
[ptb.screenXpixels, ptb.screenYpixels] = Screen('WindowSize', ptb.window);

if ptb.stereomode == 1
    SetStereoBlueLineSyncParameters(ptb.window, ptb.windowRect(4)+10);
end

% Get the centre coordinate of the window in pixels.
[ptb.xCenter, ptb.yCenter] = RectCenter(ptb.windowRect);

% Here we get the pixel size. This is not the physical size of the pixels
% but the color depth of the pixel in bits
ptb.pixelColorDepthInBits = Screen('PixelSize', ptb.window);

% Queries the display size in mm as reported by the operating system. Note
% that there are some complexities here. See Screen DisplaySize? for
% information. So always measure your screen size directly.
[ptb.width, ptb.height] = Screen('DisplaySize', ptb.screenNumber);

% Determine the width and hight of your monitor (Use caution as these values are not always correct!)
% [widthMonitor, heightMonitor]=Screen('DisplaySize', window); incorrect

ptb.pixWidth =  ptb.widthMonitor/ptb.screenXpixels;  % width of single pixel in mm 
ptb.pixHeight = ptb.heightMonitor/ptb.screenYpixels; % height of single pixel in mm

ptb.DegPerPixWidth  = 2*atand((0.5*ptb.pixWidth)/ptb.DistToMonitor);
if ptb.stereomode == 4
    ptb.PixPerDegWidth  = (1/ptb.DegPerPixWidth) * 2; % IMPORTANT: We multiply by two here, because it is a BR experiment and the screen is divided into 2!
else
    ptb.PixPerDegWidth  = (1/ptb.DegPerPixWidth);
end 
ptb.DegPerPixHeight = 2*atand((0.5*ptb.pixHeight)/ptb.DistToMonitor);
ptb.PixPerDegHeight = 1/ptb.DegPerPixHeight;
ptb.centerX = ptb.screenXpixels / 2;
ptb.centerY = ptb.screenYpixels / 2;
%......................... END Window Configuration ......................%

%.................. Screen color settings and information ................%
% Get the maximum coded luminance level (this should be 1)
ptb.maxLum = Screen('ColorRange', ptb.window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%.................. END Screen color settings and information ............% 
%% -------------- MAKE BLUELINES----------------%
ptb.bl.blueRectLeftOn   = [0,                 ptb.windowRect(4)-1,ptb.windowRect(3)/4,   ptb.windowRect(4)];
ptb.bl.blueRectLeftOff  = [ptb.windowRect(3)/4,  ptb.windowRect(4)-1, ptb.windowRect(3),    ptb.windowRect(4)];
ptb.bl.blueRectRightOn  = [0,                 ptb.windowRect(4)-1, ptb.windowRect(3)*3/4, ptb.windowRect(4)];
ptb.bl.blueRectRightOff = [ptb.windowRect(3)*3/4, ptb.windowRect(4)-1, ptb.windowRect(3),    ptb.windowRect(4)];
%............................ Timing optmization..........................%
% Query the inter-frame-interval. This refers to the minimum possible time
% between drawing to the screen
ptb.ifi = Screen('GetFlipInterval', ptb.window);

% Retreive the maximum priority number
ptb.topPriorityLevel = MaxPriority(ptb.window);

% Length of time and number of frames we will use for each drawing test
ptb.numSecs = 1;
ptb.numFrames = round(ptb.numSecs / ptb.ifi);

% Numer of frames to wait when specifying good timing. Note: the use of
% wait frames is to show a generalisable coding. For example, by using
% waitframes = 2 one would flip on every other frame. See the PTB
% documentation for details. In what follows we flip every frame.
ptb.waitframes = 1;

% We can also determine the refresh rate of our screen. The
% relationship between the two is: ifi = 1 / hertz
ptb.hertz = FrameRate(ptb.window);

% Threshold for 1 missed frame
ptb.vbl.thresh = 1.15; % 1.15 of refresh rate.

% We can also query the "nominal" refresh rate of our screen. This is
% the refresh rate as reported by the video card. This is rounded to the
% nearest integer. In reality there can be small differences between
% "hertz" and "nominalHertz"
% This is nothing to worry about. See Screen FrameRate? and Screen
% GetFlipInterval? for more information
ptb.nominalHertz = Screen('NominalFrameRate', ptb.window);
%......................... END Timing optmization ........................%         

%% ---------------------- TRIGGER --------------------------------------- %
ptb.IOport.receive      = 0; % ignore
ptb.IOport.send         = 0; % ignore
ptb.usbTrg              = 1; % use USB trigger
ptb.key.sendToIO        = 0; % Send key to IO
end