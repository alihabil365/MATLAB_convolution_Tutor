function GraphicalConvolutionTutor
% GraphicalConvolutionTutor.m
% A self-contained MATLAB GUI for teaching graphical convolution.
% Runs in MATLAB R2023a or newer. No external files or toolboxes required.
%
% To run: save this file as GraphicalConvolutionTutor.m, then type:
% GraphicalConvolutionTutor
%
% This app shows f(tau), g(t-tau), their product, and the growing output
% y(t) = integral f(tau)g(t-tau)d tau.

%% ------------------------- App State -------------------------
S = struct();
S.tau = linspace(-6, 6, 2001);          % integration variable tau
S.tValues = linspace(-6, 6, 361);       % animation/output time values
S.idx = 1;                              % current animation frame index
S.isPlaying = false;
S.dtau = S.tau(2) - S.tau(1);
S.speed = 0.06;
S.currentPreset = 'Rect x Rect';
S.customReady = false;

% Colors for a modern dark interface
C.bg = [0.07 0.08 0.10];
C.panel = [0.11 0.13 0.17];
C.panel2 = [0.15 0.17 0.22];
C.text = [0.93 0.95 0.98];
C.muted = [0.70 0.75 0.82];
C.blue = [0.23 0.55 0.95];
C.orange = [1.00 0.60 0.20];
C.green = [0.25 0.82 0.55];
C.pink = [0.95 0.35 0.70];
C.grid = [0.28 0.31 0.38];

%% ------------------------- Main Figure -------------------------
fig = uifigure('Name','Graphical Convolution Tutor', ...
    'Position',[70 70 1320 780], ...
    'Color',C.bg, ...
    'CloseRequestFcn',@closeApp);

main = uigridlayout(fig,[3 3]);
main.RowHeight = {70,'1x',170};
main.ColumnWidth = {285,'1x',330};
main.Padding = [14 14 14 14];
main.RowSpacing = 12;
main.ColumnSpacing = 12;
main.BackgroundColor = C.bg;

%% ------------------------- Header -------------------------
header = uipanel(main,'BackgroundColor',C.panel,'BorderType','none');
header.Layout.Row = 1;
header.Layout.Column = [1 3];
headerGrid = uigridlayout(header,[1 2]);
headerGrid.ColumnWidth = {'1x',260};
headerGrid.Padding = [18 8 18 8];
headerGrid.BackgroundColor = C.panel;

uilabel(headerGrid, ...
    'Text','Graphical Convolution Tutor: flip, slide, multiply, integrate', ...
    'FontSize',24,'FontWeight','bold','FontColor',C.text);

formula = uilabel(headerGrid, ...
    'Text','y(t) = \int f(\tau) g(t-\tau) d\tau', ...
    'FontSize',18,'FontWeight','bold','FontColor',C.green, ...
    'HorizontalAlignment','right');
formula.Interpreter = 'tex';

%% ------------------------- Left Control Panel -------------------------
left = uipanel(main,'Title','Signal Selection and Custom Controls', ...
    'FontWeight','bold','ForegroundColor',C.text, ...
    'BackgroundColor',C.panel,'BorderType','line');
left.Layout.Row = 2;
left.Layout.Column = 1;
leftGrid = uigridlayout(left,[15 2]);
leftGrid.RowHeight = {28,34,22,34,22,34,22,34,22,34,22,34,34,34,'1x'};
leftGrid.ColumnWidth = {'1x','1x'};
leftGrid.Padding = [14 14 14 14];
leftGrid.BackgroundColor = C.panel;

uilabel(leftGrid,'Text','Choose a preset pair:', 'FontColor',C.text,'FontWeight','bold');

presetDrop = uidropdown(leftGrid, ...
    'Items',{'Rect x Rect','Rect x Triangle','Exp Decay x Rect','Two Triangles','Custom slider signals'}, ...
    'Value','Rect x Rect', ...
    'Tooltip','Pick two signals to convolve. The app recomputes everything automatically.', ...
    'ValueChangedFcn',@presetChanged);
presetDrop.Layout.Column = [1 2];

makeSmallLabel('f amplitude');
fAmp = uislider(leftGrid,'Limits',[0.2 3],'Value',1,'MajorTicks',[0.5 1 2 3], ...
    'Tooltip','Amplitude of f(\tau).'); fAmp.Layout.Column = [1 2];

makeSmallLabel('f width / decay');
fWidth = uislider(leftGrid,'Limits',[0.3 4],'Value',2,'MajorTicks',[0.5 1 2 3 4], ...
    'Tooltip','For rectangular/triangular signals this changes width. For exponential it changes decay.'); fWidth.Layout.Column = [1 2];

makeSmallLabel('g amplitude');
gAmp = uislider(leftGrid,'Limits',[0.2 3],'Value',1,'MajorTicks',[0.5 1 2 3], ...
    'Tooltip','Amplitude of g(\tau).'); gAmp.Layout.Column = [1 2];

makeSmallLabel('g width / shift');
gWidth = uislider(leftGrid,'Limits',[0.3 4],'Value',2,'MajorTicks',[0.5 1 2 3 4], ...
    'Tooltip','Width of g(\tau) before it is flipped and shifted.'); gWidth.Layout.Column = [1 2];

makeSmallLabel('Animation speed');
speedSlider = uislider(leftGrid,'Limits',[0.01 0.18],'Value',S.speed, ...
    'MajorTicks',[0.01 0.06 0.12 0.18], ...
    'Tooltip','Lower number means faster animation. Higher number means slower animation.', ...
    'ValueChangedFcn',@speedChanged);
speedSlider.Layout.Column = [1 2];

resetBtn = uibutton(leftGrid,'push','Text','Reset View','ButtonPushedFcn',@resetView, ...
    'Tooltip','Return to the first time position and refresh plots.');
randomBtn = uibutton(leftGrid,'push','Text','Try Random Custom','ButtonPushedFcn',@randomCustom, ...
    'Tooltip','Creates a random pair of rectangular/triangular-looking signals using the sliders.');

customNote = uitextarea(leftGrid, ...
    'Value',{'Tip: Pick "Custom slider signals" to build your own simple pulse pair using the four sliders above.'; ...
             'Graphical convolution idea: g is flipped, shifted by t, multiplied with f, then the shaded product area becomes y(t).'}, ...
    'Editable','off','FontColor',C.muted,'BackgroundColor',C.panel2,'FontSize',12);
customNote.Layout.Row = [14 15];
customNote.Layout.Column = [1 2];

% Attach common callbacks after controls are created.
fAmp.ValueChangingFcn = @sliderLive;
fWidth.ValueChangingFcn = @sliderLive;
gAmp.ValueChangingFcn = @sliderLive;
gWidth.ValueChangingFcn = @sliderLive;
fAmp.ValueChangedFcn = @sliderChanged;
fWidth.ValueChangedFcn = @sliderChanged;
gAmp.ValueChangedFcn = @sliderChanged;
gWidth.ValueChangedFcn = @sliderChanged;

%% ------------------------- Center Plot Area -------------------------
plotPanel = uipanel(main,'Title','Visual Convolution Workspace', ...
    'FontWeight','bold','ForegroundColor',C.text, ...
    'BackgroundColor',C.panel,'BorderType','line');
plotPanel.Layout.Row = 2;
plotPanel.Layout.Column = 2;
plotGrid = uigridlayout(plotPanel,[3 1]);
plotGrid.RowHeight = {'1x','1x','1x'};
plotGrid.Padding = [12 8 12 12];
plotGrid.RowSpacing = 8;
plotGrid.BackgroundColor = C.panel;

axSignals = uiaxes(plotGrid);
axProduct = uiaxes(plotGrid);
axOutput = uiaxes(plotGrid);
styleAxes(axSignals,'Signals in \tau-domain','\tau','Amplitude');
styleAxes(axProduct,'Overlap product: f(\tau)g(t-\tau)','\tau','Product value');
styleAxes(axOutput,'Accumulating convolution output y(t)','t','y(t)');

%% ------------------------- Right Explanation Panel -------------------------%%

right = uipanel(main,'Title','Step-by-Step Explanation', ...
    'FontWeight','bold','ForegroundColor',C.text, ...
    'BackgroundColor',C.panel,'BorderType','line');
right.Layout.Row = 2;
right.Layout.Column = 3;

rightGrid = uigridlayout(right,[6 1]);
rightGrid.RowHeight = {34,34,34,34,'1x',44};
rightGrid.Padding = [14 14 14 14];
rightGrid.BackgroundColor = C.panel;

phaseLabel = uilabel(rightGrid,'Text','Current step: 1. Start with f(\tau) and g(\tau)', ...
    'FontSize',15,'FontWeight','bold','FontColor',C.green);
phaseLabel.Interpreter = 'tex';

timeLabel = uilabel(rightGrid,'Text','Current t = -6.00', ...
    'FontSize',14,'FontColor',C.text);

yLabel = uilabel(rightGrid,'Text','Current y(t) = 0.000', ...
    'FontSize',14,'FontColor',C.text);

overlapLabel = uilabel(rightGrid,'Text','Overlap status: none yet', ...
    'FontSize',14,'FontColor',C.text);

explainBox = uitextarea(rightGrid, ...
    'Editable','off','FontSize',13,'FontColor',C.text, ...
    'BackgroundColor',C.panel2);

explainBox.Value = {
    'Welcome! Press Play or Step Forward.'
    ''
    'Convolution is a moving area calculation.'
    'At each value of t:'
    '1. Flip g(τ) → g(-τ)'
    '2. Shift → g(t−τ)'
    '3. Multiply with f(τ)'
    '4. Compute the area (integral)'
    ''
    'That area becomes one point of the output y(t).'
    ''
    '----------------------------------------'
    'WHY SHOULD I CARE?'
    ''
    'Convolution describes how systems respond to inputs.'
    'Anytime an input passes through a system, convolution happens.'
    ''
    'Real-life examples:'
    '• Audio: reverb = sound convolved with room echo'
    '• Circuits: output voltage = input convolved with system response'
    '• Images: blur and sharpening filters use convolution'
    '• Biomedical: ECG/EEG signals are filtered using convolution'
    '• Communications: signals change shape through channels via convolution'
    ''
    '----------------------------------------'
    'IN THIS GUI:'
    'f(τ) = input signal'
    'g(t−τ) = flipped and shifted system response'
    'Shaded overlap area = current y(t)'
    ''
    'Watch how the output builds as the signals slide!'
};

hint = uilabel(rightGrid,'Text','Learning goal: the output point equals the shaded overlap area.', ...
    'FontColor',C.muted,'FontSize',12,'HorizontalAlignment','center');

%% ------------------------- Bottom Controls -------------------------
bottom = uipanel(main,'Title','Animation Controls', ...
    'FontWeight','bold','ForegroundColor',C.text, ...
    'BackgroundColor',C.panel,'BorderType','line');
bottom.Layout.Row = 3;
bottom.Layout.Column = [1 3];
bottomGrid = uigridlayout(bottom,[2 8]);
bottomGrid.RowHeight = {44,'1x'};
bottomGrid.ColumnWidth = {90,90,90,90,'1x',105,105,105};
bottomGrid.Padding = [16 12 16 14];
bottomGrid.BackgroundColor = C.panel;

playBtn = uibutton(bottomGrid,'push','Text','Play','FontWeight','bold','ButtonPushedFcn',@playPause, ...
    'Tooltip','Start or pause the animation.');
stepBackBtn = uibutton(bottomGrid,'push','Text','Step Back','ButtonPushedFcn',@stepBack, ...
    'Tooltip','Move one frame backward.');
stepBtn = uibutton(bottomGrid,'push','Text','Step Forward','ButtonPushedFcn',@stepForward, ...
    'Tooltip','Move one frame forward.');
restartBtn = uibutton(bottomGrid,'push','Text','Restart','ButtonPushedFcn',@restartAnim, ...
    'Tooltip','Go back to the first frame.');

animSlider = uislider(bottomGrid,'Limits',[1 numel(S.tValues)],'Value',1, ...
    'MajorTicks',round(linspace(1,numel(S.tValues),7)), ...
    'Tooltip','Drag to manually choose the current value of t.', ...
    'ValueChangingFcn',@timeSliderLive, ...
    'ValueChangedFcn',@timeSliderChanged);
animSlider.Layout.Column = 5;

flipBtn = uibutton(bottomGrid,'push','Text','Show Flip','ButtonPushedFcn',@showFlipConcept, ...
    'Tooltip','Jump to a view that emphasizes the flipping step.');
overlapBtn = uibutton(bottomGrid,'push','Text','Max Overlap','ButtonPushedFcn',@jumpMaxOverlap, ...
    'Tooltip','Jump to the time where the overlap area is largest.');
endBtn = uibutton(bottomGrid,'push','Text','Full Output','ButtonPushedFcn',@showFullOutput, ...
    'Tooltip','Show the completed convolution output curve.');

stepsText = uitextarea(bottomGrid,'Editable','off','FontSize',12, ...
    'FontColor',C.muted,'BackgroundColor',C.panel2, ...
    'Value',{'How to use: 1) Choose a preset. 2) Press Play. 3) Watch g flip and slide. 4) The shaded product area becomes one point on y(t). 5) Step through slowly when the signals start overlapping.'});
stepsText.Layout.Row = 2;
stepsText.Layout.Column = [1 8];

%% ------------------------- Timer -------------------------
S.timer = timer('ExecutionMode','fixedSpacing','Period',S.speed,'TimerFcn',@timerTick);

%% ------------------------- Initial Plot -------------------------
computeSignals();
updatePlot();

%% ========================= Nested Functions =========================
    function makeSmallLabel(txt)
        lab = uilabel(leftGrid,'Text',txt,'FontColor',C.muted,'FontSize',12);
        lab.Layout.Column = [1 2];
    end

    function styleAxes(ax,titleText,xlab,ylab)
        ax.Color = [0.06 0.07 0.09];
        ax.XColor = C.text;
        ax.YColor = C.text;
        ax.GridColor = C.grid;
        ax.MinorGridColor = C.grid;
        ax.FontName = 'Arial';
        ax.FontSize = 11;
        grid(ax,'on');
        title(ax,titleText,'Color',C.text,'FontWeight','bold');
        xlabel(ax,xlab,'Color',C.text);
        ylabel(ax,ylab,'Color',C.text);
    end

    function computeSignals()
        S.currentPreset = presetDrop.Value;
        tau = S.tau;
        A1 = fAmp.Value; W1 = fWidth.Value;
        A2 = gAmp.Value; W2 = gWidth.Value;

        switch S.currentPreset
            case 'Rect x Rect'
                S.f = A1 * double(abs(tau) <= W1/2);
                S.g = A2 * double(abs(tau) <= W2/2);
                S.description = 'Two rectangular pulses. Their convolution becomes a triangle because the overlap length grows, then shrinks linearly.';

            case 'Rect x Triangle'
                S.f = A1 * double(abs(tau) <= W1/2);
                S.g = A2 * max(1 - abs(tau)/(W2/2), 0);
                S.description = 'A rectangle is sliding across a triangle. The output is the area under the portion of the triangle covered by the rectangle.';

            case 'Exp Decay x Rect'
                S.f = A1 * exp(-max(tau,0)/max(W1,0.1)) .* double(tau >= 0);
                S.g = A2 * double(abs(tau) <= W2/2);
                S.description = 'A causal exponential is averaged through a sliding rectangular window. Notice the output rises and then decays.';

            case 'Two Triangles'
                S.f = A1 * max(1 - abs(tau)/(W1/2), 0);
                S.g = A2 * max(1 - abs(tau)/(W2/2), 0);
                S.description = 'Two triangles create a smooth rounded convolution because the overlap product changes gradually.';

            case 'Custom slider signals'
                S.f = A1 * (0.65*double(abs(tau+0.8) <= W1/2) + 0.35*max(1 - abs(tau-1.1)/(0.55*W1),0));
                S.g = A2 * (0.55*double(abs(tau-0.5) <= W2/2) + 0.45*max(1 - abs(tau+1.3)/(0.65*W2),0));
                S.description = 'Custom slider mode combines rectangular and triangular parts. Use the sliders to see how amplitude and width affect y(t).';
        end

        % Precompute convolution numerically for all t values.
        S.y = zeros(size(S.tValues));
        S.gShiftedAll = zeros(numel(S.tValues),numel(tau));
        for k = 1:numel(S.tValues)
            t = S.tValues(k);
            gShift = interp1(tau,S.g,t - tau,'linear',0); % g(t - tau): flipped and shifted
            S.gShiftedAll(k,:) = gShift;
            S.y(k) = trapz(tau,S.f .* gShift);
        end
    end

    function updatePlot()
        if ~isvalid(fig); return; end
        k = max(1,min(numel(S.tValues),round(S.idx)));
        S.idx = k;
        t = S.tValues(k);
        gShift = S.gShiftedAll(k,:);
        product = S.f .* gShift;
        yCurrent = S.y(k);

        cla(axSignals); hold(axSignals,'on');
        plot(axSignals,S.tau,S.f,'LineWidth',2.4,'Color',C.blue,'DisplayName','f(\tau)');
        plot(axSignals,S.tau,gShift,'LineWidth',2.4,'Color',C.orange,'DisplayName','g(t-\tau)');
        xline(axSignals,t,'--','Color',C.green,'LineWidth',1.2,'DisplayName','current t');
        legend(axSignals,'TextColor',C.text,'Color',C.panel2,'Location','northeast');
        xlim(axSignals,[min(S.tau) max(S.tau)]);
        ylim(axSignals,[min(-0.15,min([S.f gShift])-0.2) max(1.2,max([S.f gShift])+0.4)]);
        hold(axSignals,'off');

        cla(axProduct); hold(axProduct,'on');
        area(axProduct,S.tau,product,'FaceAlpha',0.35,'FaceColor',C.green,'EdgeColor','none','DisplayName','shaded product area');
        plot(axProduct,S.tau,product,'LineWidth',2.1,'Color',C.green,'DisplayName','f(\tau)g(t-\tau)');
        yline(axProduct,0,'Color',C.grid,'LineWidth',1);
        legend(axProduct,'TextColor',C.text,'Color',C.panel2,'Location','northeast');
        xlim(axProduct,[min(S.tau) max(S.tau)]);
        ylim(axProduct,[min(-0.1,min(product)-0.15) max(0.4,max(product)+0.3)]);
        hold(axProduct,'off');

        cla(axOutput); hold(axOutput,'on');
        plot(axOutput,S.tValues,S.y,'Color',[0.35 0.35 0.35],'LineWidth',1.4,'DisplayName','full y(t), hidden guide');
        plot(axOutput,S.tValues(1:k),S.y(1:k),'LineWidth',2.8,'Color',C.pink,'DisplayName','built output y(t)');
        scatter(axOutput,t,yCurrent,70,C.green,'filled','DisplayName','current output point');
        xline(axOutput,t,'--','Color',C.green,'LineWidth',1.2);
        legend(axOutput,'TextColor',C.text,'Color',C.panel2,'Location','northeast');
        xlim(axOutput,[min(S.tValues) max(S.tValues)]);
        ylim(axOutput,[min(S.y)-0.25 max(S.y)+0.35]);
        hold(axOutput,'off');

        animSlider.Value = k;
        timeLabel.Text = sprintf('Current t = %.2f',t);
        yLabel.Text = sprintf('Current y(t) = %.4f',yCurrent);

        overlapAmount = trapz(S.tau,double(product > 1e-6));
        if overlapAmount < 0.05
            overlapLabel.Text = 'Overlap status: no meaningful overlap yet';
            phaseLabel.Text = 'Current step: waiting for overlap';
        elseif k < numel(S.tValues)*0.45
            overlapLabel.Text = 'Overlap status: overlap is growing';
            phaseLabel.Text = 'Current step: g(t-\tau) is sliding into f(\tau)';
        elseif k < numel(S.tValues)*0.65
            overlapLabel.Text = 'Overlap status: strong overlap';
            phaseLabel.Text = 'Current step: product area is large';
        else
            overlapLabel.Text = 'Overlap status: overlap is shrinking';
            phaseLabel.Text = 'Current step: output is finishing';
        end
        phaseLabel.Interpreter = 'tex';

        explainBox.Value = buildExplanation(t,yCurrent,overlapAmount);
        drawnow limitrate;
    end

    function txt = buildExplanation(t,yCurrent,overlapAmount)
        txt = {
            sprintf('Preset: %s',S.currentPreset)
            ''
            S.description
            ''
            sprintf('At this frame, t = %.2f.',t)
            'The orange curve is g(t-\tau). This means the original g(\tau) has been flipped horizontally and then shifted.'
            'The green shaded curve is f(\tau) multiplied by g(t-\tau). Only the region where both signals overlap contributes to the convolution.'
            sprintf('The approximate shaded area is y(t) = %.4f.',yCurrent)
            ''
            'Big idea: convolution is not just multiplying two signals once. It is repeating this multiply-and-area calculation for every possible shift t.'
            sprintf('Current overlap width estimate: %.2f units of \tau.',overlapAmount)
            };
    end

    function presetChanged(~,~)
        stopPlayback();
        S.idx = 1;
        computeSignals();
        updatePlot();
    end

    function sliderLive(src,event)
        src.Value = event.Value;
        computeSignals();
        updatePlot();
    end

    function sliderChanged(~,~)
        computeSignals();
        updatePlot();
    end

    function speedChanged(~,~)
        S.speed = speedSlider.Value;
        if isvalid(S.timer)
            wasPlaying = S.isPlaying;
            stopPlayback();
            S.timer.Period = S.speed;
            if wasPlaying
                S.isPlaying = true;
                playBtn.Text = 'Pause';
                start(S.timer);
            end
        end
    end

    function playPause(~,~)
        if S.isPlaying
            stopPlayback();
        else
            S.isPlaying = true;
            playBtn.Text = 'Pause';
            start(S.timer);
        end
    end

    function stopPlayback()
        S.isPlaying = false;
        playBtn.Text = 'Play';
        if isfield(S,'timer') && isvalid(S.timer) && strcmp(S.timer.Running,'on')
            stop(S.timer);
        end
    end

    function timerTick(~,~)
        if S.idx >= numel(S.tValues)
            stopPlayback();
            return;
        end
        S.idx = S.idx + 1;
        updatePlot();
    end

    function stepForward(~,~)
        stopPlayback();
        S.idx = min(S.idx + 1,numel(S.tValues));
        updatePlot();
    end

    function stepBack(~,~)
        stopPlayback();
        S.idx = max(S.idx - 1,1);
        updatePlot();
    end

    function restartAnim(~,~)
        stopPlayback();
        S.idx = 1;
        updatePlot();
    end

    function resetView(~,~)
        stopPlayback();
        S.idx = 1;
        presetDrop.Value = 'Rect x Rect';
        fAmp.Value = 1; fWidth.Value = 2; gAmp.Value = 1; gWidth.Value = 2;
        computeSignals();
        updatePlot();
    end

    function timeSliderLive(~,event)
        stopPlayback();
        S.idx = round(event.Value);
        updatePlot();
    end

    function timeSliderChanged(~,~)
        stopPlayback();
        S.idx = round(animSlider.Value);
        updatePlot();
    end

    function showFlipConcept(~,~)
        stopPlayback();
        [~,S.idx] = min(abs(S.tValues - 0));
        updatePlot();
        explainBox.Value = [explainBox.Value; {''; 'Flip focus: g(t-\tau) includes a negative \tau term, so the signal is mirrored before it slides. At t = 0, you mainly see the flipped version centered around the origin.'}];
    end

    function jumpMaxOverlap(~,~)
        stopPlayback();
        [~,S.idx] = max(abs(S.y));
        updatePlot();
    end

    function showFullOutput(~,~)
        stopPlayback();
        S.idx = numel(S.tValues);
        updatePlot();
    end

    function randomCustom(~,~)
        stopPlayback();
        presetDrop.Value = 'Custom slider signals';
        fAmp.Value = 0.6 + 2.2*rand;
        gAmp.Value = 0.6 + 2.2*rand;
        fWidth.Value = 0.8 + 2.8*rand;
        gWidth.Value = 0.8 + 2.8*rand;
        S.idx = 1;
        computeSignals();
        updatePlot();
    end

    function closeApp(~,~)
        try
            stopPlayback();
            if isfield(S,'timer') && isvalid(S.timer)
                delete(S.timer);
            end
        catch
        end
        delete(fig);
    end
end
