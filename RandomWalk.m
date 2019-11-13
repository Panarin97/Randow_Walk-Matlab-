classdef RandomWalk < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        UIAxes                          matlab.ui.control.UIAxes
        StartButton                     matlab.ui.control.Button
        YEditFieldLabel                 matlab.ui.control.Label
        YEditField                      matlab.ui.control.EditField
        XEditFieldLabel                 matlab.ui.control.Label
        XEditField                      matlab.ui.control.EditField
        TabGroup                        matlab.ui.container.TabGroup
        BasicTab                        matlab.ui.container.Tab
        MarkerSettingsPanel             matlab.ui.container.Panel
        MarkerDropDownLabel             matlab.ui.control.Label
        MarkerDropDown                  matlab.ui.control.DropDown
        SizeSpinnerLabel                matlab.ui.control.Label
        MarkerSizeSpinner               matlab.ui.control.Spinner
        FaceColorButton                 matlab.ui.control.Button
        EdgeColorButton                 matlab.ui.control.Button
        TrailSettingsPanel              matlab.ui.container.Panel
        StyleDropDownLabel              matlab.ui.control.Label
        StyleDropDown                   matlab.ui.control.DropDown
        SizeSpinner_2Label              matlab.ui.control.Label
        TrailSizeSpinner                matlab.ui.control.Spinner
        TrailColorButton                matlab.ui.control.Button
        ClearTrailButton                matlab.ui.control.Button
        MovementPanel                   matlab.ui.container.Panel
        StepEditFieldLabel              matlab.ui.control.Label
        StepEditField                   matlab.ui.control.NumericEditField
        AdvancedTab                     matlab.ui.container.Tab
        BoundarySettingsPanel           matlab.ui.container.Panel
        BehaviorDropDownLabel           matlab.ui.control.Label
        BehaviorDropDown                matlab.ui.control.DropDown
        XDeltaEditFieldLabel            matlab.ui.control.Label
        XDeltaEditField                 matlab.ui.control.NumericEditField
        YDeltaEditFieldLabel            matlab.ui.control.Label
        YDeltaEditField                 matlab.ui.control.NumericEditField
        ZDeltaEditFieldLabel            matlab.ui.control.Label
        ZDeltaEditField                 matlab.ui.control.NumericEditField
        InitialAxisLimitsPanel          matlab.ui.container.Panel
        XLimitEditFieldLabel            matlab.ui.control.Label
        XLimitEditField                 matlab.ui.control.NumericEditField
        YLimitEditFieldLabel            matlab.ui.control.Label
        YLimitEditField                 matlab.ui.control.NumericEditField
        ZLimitEditFieldLabel            matlab.ui.control.Label
        ZLimitEditField                 matlab.ui.control.NumericEditField
        AngleDistributionsettingsPanel  matlab.ui.container.Panel
        DiscreteAngleDistributionCheckBox  matlab.ui.control.CheckBox
        NumberofAngles2DEditFieldLabel  matlab.ui.control.Label
        NumberofAngles2DEditField       matlab.ui.control.NumericEditField
        ZEditFieldLabel                 matlab.ui.control.Label
        ZEditField                      matlab.ui.control.EditField
        DimensionRadio                  matlab.ui.container.ButtonGroup
        Radio2D                         matlab.ui.control.RadioButton
        Radio3D                         matlab.ui.control.RadioButton
        ResetButton                     matlab.ui.control.Button
    end

    
    properties (Access = private)
        Running % True when random walk is running, otherwise false
        Coordinates % Current coordinates of the walk
        Hplot % Handle to the plot
        TrailLine % Animated line used as a trail for the walk
        PlotDimensions % In how many dimensions is the walk happening, 2 or 3
        MarkerValue % Marker used in the plot
        TrailStyle % Style of the trail line
    end
    
    methods (Access = private)
               
        function axisLim = getNewAxisLim(~, axisLim, axisCoordinate, delta)
        % GETNEWAXISLIM Calculates new axis limits to keep the walk
        % visible.
        %   AXISLIM = GETNEWAXISLIM(~, AXISLIM, AXISCOORDINATE, DELTA)
        %   Calculates new axis limits for an axis based on current axis
        %   limits AXISLIM, coordinates of the walk in that axis
        %   AXISCOORDINATE and amount to change the limits DELTA.
        
            if axisCoordinate < axisLim(1)
                axisLim(1) = axisLim(1) - delta;
            elseif axisCoordinate > axisLim(2)
                axisLim(2) = axisLim(2) + delta;
            end
        end
        
        function axisCoordinate = jumpToOtherSide(app, axisLim, axisCoordinate)
        % JUMPTOOTHERSIDE Moves the walk to the other side of the plot if
        % it goes out side the limits.
        %   AXISCOORDINATE = JUMPTOOTHERSIDE(APP, AXISLIM, AXISCOORDINATE)
        %   Calculates new coorinate in given axis based on axis limits
        %   AXISLIM and current coordinates in given axis AXISCOORDINATE.
        %   Clears the point in the trail line to avoid weird lines across
        %   the plot.
            
            if axisCoordinate < axisLim(1)
                axisCoordinate = axisLim(2) + (axisLim(1) - axisCoordinate);
                clearpoints(app.TrailLine);
            elseif axisCoordinate > axisLim(2)
                axisCoordinate = axisLim(1) + (axisCoordinate - axisLim(2));
                clearpoints(app.TrailLine);
            end
        end
        
        function [] = resetWalk(app)
        % RESETWALK Resets the walk to the initial conditions.
        %   [] = RESETWALK(APP) Resets the coordinates of the walk, axis
        %   limits and clears the trail.
            
            app.Coordinates = [0 0 0]; 
            app.UIAxes.XLim(1) = -app.XLimitEditField.Value;
            app.UIAxes.XLim(2) = app.XLimitEditField.Value;
            app.UIAxes.YLim(1) = -app.YLimitEditField.Value;
            app.UIAxes.YLim(2) = app.YLimitEditField.Value;
            
            app.UIAxes.ZLim(1) = -app.ZLimitEditField.Value;
            app.UIAxes.ZLim(2) = app.ZLimitEditField.Value;
            
            clearpoints(app.TrailLine);
            
            app.Hplot.XData = app.Coordinates(1);
            app.Hplot.YData = app.Coordinates(2);
            app.Hplot.ZData = app.Coordinates(3);
        end
        
        function coordinates = calculateCoordinates2D(app)
        % CALCULATECOORDINATES2D Calculates new coordinates for the walk in
        % 2D.
        %   COORDINATES = CALCULATECOORDINATES2D(APP) Calculates
        %   coordinates for the walk in 2D based on current coordinates using
        %   uniform or discreate distibution with given number of angles based on user input.
            
            if app.DiscreteAngleDistributionCheckBox.Value
                u = randi(app.NumberofAngles2DEditField.Value) / app.NumberofAngles2DEditField.Value;
                phi = 2*pi*u;
            else
                phi = rand*2*pi;
            end
            coordinates = app.Coordinates + app.StepEditField.Value*[cos(phi) sin(phi) 0];
        end
        
        function coordinates = calculateCoordinates3D(app)
        % CALCULATECOORDINATES3D Calculates new coordinates for the walk in
        % 3D.
        %   COORDINATES = CALCULATECOORDINATES3D Calculates
        %   coordinates for the walk in 3D based on current coordinates using
        %   uniform or discreate distibution (rectangular walk) based on user input.
            
            if app.DiscreteAngleDistributionCheckBox.Value
                % Do only the rectangular discreate walk in 3D
                u = randi(6);
                switch u
                    case 1; phi = 0; theta = 0;
                    case 2; phi = 0; theta = pi;
                    case 3; phi = 0; theta = pi/2;
                    case 4; phi = pi/2; theta = pi/2;
                    case 5; phi = pi; theta = pi/2;
                    case 6; phi = 3*pi/2; theta = pi/2;
                end
            else
                theta = acos(1-2*rand);
                phi = rand*2*pi;
            end
            
            coordinates = app.Coordinates + app.StepEditField.Value*[sin(theta)*cos(phi) sin(theta)*sin(phi) cos(theta)];
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.Running = false;
            
            app.MarkerValue = 'o';
            app.MarkerDropDown.Items = {'Point', 'Circle', 'Plus', 'None'};
            app.MarkerDropDown.ItemsData = {'.', 'o', '+', 'none'};
            app.MarkerDropDown.Value = app.MarkerValue;
            
            app.TrailStyle = 'none';
            app.StyleDropDown.Items = {'Solid line', 'Dashed line', 'Dotted line', 'Dash-dotted line' ,'None'};
            app.StyleDropDown.ItemsData = {'-', '--', ':', '-.', 'none'};
            app.StyleDropDown.Value = app.TrailStyle;
            
            app.BehaviorDropDown.Items = {'Expanding', 'Constant'};
            app.BehaviorDropDown.ItemsData = {0, 1};
            app.BehaviorDropDown.Value = 0;
            
            app.Coordinates = [0 0 0];
            app.Hplot = plot3(app.UIAxes, app.Coordinates(1), app.Coordinates(2), app.Coordinates(3), 'Marker', app.MarkerValue, ...
                        'MarkerSize', app.MarkerSizeSpinner.Value, ...
                        'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k');
            
            app.TrailLine = animatedline(app.UIAxes);
            app.TrailLine.LineStyle = app.TrailStyle;
            
            % Start in 2D
            app.PlotDimensions = 2;
            app.UIAxes.View = [0 90];
                       
            resetWalk(app);
        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            if app.Running
                app.Running = false;
            else                                     
                app.Running = true;
                app.StartButton.Text = "Stop";
                
                while app.Running                    
                    if app.PlotDimensions == 2
                        app.Coordinates = calculateCoordinates2D(app);
                    else
                        app.Coordinates = calculateCoordinates3D(app);
                        
                        % Keep the marker in sight
                        if app.BehaviorDropDown.Value == 0
                            % Expand the axis limits
                            app.UIAxes.ZLim = getNewAxisLim(app, app.UIAxes.ZLim, app.Coordinates(3), app.ZDeltaEditField.Value);
                        else
                            % Move the marker to the other side of the plot
                            app.Coordinates(3) = jumpToOtherSide(app, app.UIAxes.ZLim, app.Coordinates(3));
                        end

                    end
                    
                    % Show the current coordinate values
                    app.ZEditField.Value = sprintf('%+8.4f', app.Coordinates(3));
                    app.XEditField.Value = sprintf('%+8.4f', app.Coordinates(1));
                    app.YEditField.Value = sprintf('%+8.4f', app.Coordinates(2));
                    
                    % Set the marker to current coordinates
                    app.Hplot.XData = app.Coordinates(1);
                    app.Hplot.YData = app.Coordinates(2);
                    app.Hplot.ZData = app.Coordinates(3);
                    
                    % Keep the marker in sight    
                    if app.BehaviorDropDown.Value == 0
                        % Expand the axis limits
                        app.UIAxes.XLim = getNewAxisLim(app, app.UIAxes.XLim, app.Coordinates(1), app.XDeltaEditField.Value);
                        app.UIAxes.YLim = getNewAxisLim(app, app.UIAxes.YLim, app.Coordinates(2), app.YDeltaEditField.Value);
                    else
                        % Move the marker to the other side of the plot
                        app.Coordinates(1) = jumpToOtherSide(app, app.UIAxes.XLim, app.Coordinates(1));
                        app.Coordinates(2) = jumpToOtherSide(app, app.UIAxes.YLim, app.Coordinates(2));
                    end
                    
                    % Add the current coodrinates to the trail
                    addpoints(app.TrailLine, app.Coordinates(1), app.Coordinates(2), app.Coordinates(3))

                    drawnow
                end
                app.StartButton.Text = "Start";
            end            
        end

        % Value changed function: MarkerDropDown
        function MarkerDropDownValueChanged(app, event)
            % Show error dialog if trail line style is  none and trying to
            % set marker to none. Otherwise change the marker.
            if strcmp(app.TrailStyle, 'none') && strcmp(app.MarkerDropDown.Value, 'none')
                errordlg('Marker and Line style can not be set to "None" at the same time','Error');
                app.MarkerDropDown.Value = app.MarkerValue;
            else
                app.MarkerValue = app.MarkerDropDown.Value;
                app.Hplot.Marker = app.MarkerValue;
            end
        end

        % Button pushed function: FaceColorButton
        function FaceColorButtonPushed(app, event)
            app.Hplot.MarkerFaceColor = uisetcolor;
            figure(app.UIFigure); % Keep focus on the app window
        end

        % Button pushed function: EdgeColorButton
        function EdgeColorButtonPushed(app, event)
            app.Hplot.MarkerEdgeColor = uisetcolor;
            figure(app.UIFigure); % Keep focus on the app window
        end

        % Value changed function: MarkerSizeSpinner
        function MarkerSizeSpinnerValueChanged(app, event)
            app.Hplot.MarkerSize = app.MarkerSizeSpinner.Value;
        end

        % Button pushed function: TrailColorButton
        function TrailColorButtonPushed(app, event)
            app.TrailLine.Color = uisetcolor;
            figure(app.UIFigure); % Keep focus on the app window
        end

        % Value changed function: StyleDropDown
        function StyleDropDownValueChanged(app, event)
            % Show error dialog if marker is  none and trying to set the
            % trail line style to none. Otherwise change the trail line
            % style.
            if strcmp(app.MarkerValue, 'none') && strcmp(app.StyleDropDown.Value, 'none')
                errordlg('Marker and Line style can not be set to "None" at the same time','Error');
                app.StyleDropDown.Value = app.TrailStyle;
            else
                app.TrailStyle = app.StyleDropDown.Value;
                app.TrailLine.LineStyle = app.TrailStyle;
            end
        end

        % Value changed function: TrailSizeSpinner
        function TrailSizeSpinnerValueChanged(app, event)
            app.TrailLine.LineWidth = app.TrailSizeSpinner.Value;
        end

        % Callback function
        function DimensionDropDownValueChanged(app, event)
            app.PlotDimensions = app.DimensionDropDown.Value;
        end

        % Selection changed function: DimensionRadio
        function DimensionRadioSelectionChanged(app, event)
            if app.DimensionRadio.SelectedObject == app.Radio2D
                app.PlotDimensions = 2;
                app.UIAxes.View = [0 90];
                set(app.ZEditField, 'enable', 'off');
                
                if app.DiscreteAngleDistributionCheckBox.Value
                    set(app.NumberofAngles2DEditField, 'enable', 'on');
                end
            else
                app.PlotDimensions = 3;
                app.UIAxes.View = [-37.5 30];
                set(app.ZEditField, 'enable', 'on')
                
                % Hide number of angles edit field for 3D
                set(app.NumberofAngles2DEditField, 'enable', 'off');
            end
        end

        % Value changed function: DiscreteAngleDistributionCheckBox
        function DiscreteAngleDistributionCheckBoxValueChanged(app, event)
            if app.DiscreteAngleDistributionCheckBox.Value
                % Show number of angles edit field only for 2D
                if app.PlotDimensions == 2
                    set(app.NumberofAngles2DEditField, 'enable', 'on')
                end
            else
                set(app.NumberofAngles2DEditField, 'enable', 'off')
            end
        end

        % Button pushed function: ResetButton
        function ResetButtonPushed(app, event)
            resetWalk(app);
        end

        % Value changed function: BehaviorDropDown
        function BehaviorDropDownValueChanged(app, event)
            if app.BehaviorDropDown.Value == 0
                set(app.XDeltaEditField, 'enable', 'on');
                set(app.YDeltaEditField, 'enable', 'on');
                set(app.ZDeltaEditField, 'enable', 'on');
            else
                set(app.XDeltaEditField, 'enable', 'off');
                set(app.YDeltaEditField, 'enable', 'off');
                set(app.ZDeltaEditField, 'enable', 'off');
            end
            
        end

        % Button pushed function: ClearTrailButton
        function ClearTrailButtonPushed(app, event)
            clearpoints(app.TrailLine);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 813 577];
            app.UIFigure.Name = 'UI Figure';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Random Walk')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            app.UIAxes.PlotBoxAspectRatio = [1 1 1];
            app.UIAxes.Position = [48 73 481 463];

            % Create StartButton
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.Position = [557 37 100 22];
            app.StartButton.Text = 'Start';

            % Create YEditFieldLabel
            app.YEditFieldLabel = uilabel(app.UIFigure);
            app.YEditFieldLabel.HorizontalAlignment = 'right';
            app.YEditFieldLabel.Position = [211 37 25 22];
            app.YEditFieldLabel.Text = 'Y';

            % Create YEditField
            app.YEditField = uieditfield(app.UIFigure, 'text');
            app.YEditField.Editable = 'off';
            app.YEditField.HorizontalAlignment = 'right';
            app.YEditField.Position = [251 37 100 22];

            % Create XEditFieldLabel
            app.XEditFieldLabel = uilabel(app.UIFigure);
            app.XEditFieldLabel.HorizontalAlignment = 'right';
            app.XEditFieldLabel.Position = [54 37 25 22];
            app.XEditFieldLabel.Text = 'X';

            % Create XEditField
            app.XEditField = uieditfield(app.UIFigure, 'text');
            app.XEditField.Editable = 'off';
            app.XEditField.HorizontalAlignment = 'right';
            app.XEditField.Position = [94 37 100 22];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [549 112 231 401];

            % Create BasicTab
            app.BasicTab = uitab(app.TabGroup);
            app.BasicTab.Title = 'Basic';
            app.BasicTab.BackgroundColor = [0.902 0.902 0.902];

            % Create MarkerSettingsPanel
            app.MarkerSettingsPanel = uipanel(app.BasicTab);
            app.MarkerSettingsPanel.TitlePosition = 'centertop';
            app.MarkerSettingsPanel.Title = 'Marker Settings';
            app.MarkerSettingsPanel.BackgroundColor = [0.8 0.8 0.8];
            app.MarkerSettingsPanel.FontWeight = 'bold';
            app.MarkerSettingsPanel.Position = [11 232 210 132];

            % Create MarkerDropDownLabel
            app.MarkerDropDownLabel = uilabel(app.MarkerSettingsPanel);
            app.MarkerDropDownLabel.HorizontalAlignment = 'right';
            app.MarkerDropDownLabel.Position = [10 76 43 22];
            app.MarkerDropDownLabel.Text = 'Marker';

            % Create MarkerDropDown
            app.MarkerDropDown = uidropdown(app.MarkerSettingsPanel);
            app.MarkerDropDown.ValueChangedFcn = createCallbackFcn(app, @MarkerDropDownValueChanged, true);
            app.MarkerDropDown.Position = [68 76 134 22];

            % Create SizeSpinnerLabel
            app.SizeSpinnerLabel = uilabel(app.MarkerSettingsPanel);
            app.SizeSpinnerLabel.HorizontalAlignment = 'right';
            app.SizeSpinnerLabel.Position = [10 47 29 22];
            app.SizeSpinnerLabel.Text = 'Size';

            % Create MarkerSizeSpinner
            app.MarkerSizeSpinner = uispinner(app.MarkerSettingsPanel);
            app.MarkerSizeSpinner.Limits = [1 Inf];
            app.MarkerSizeSpinner.ValueChangedFcn = createCallbackFcn(app, @MarkerSizeSpinnerValueChanged, true);
            app.MarkerSizeSpinner.Position = [68 47 134 22];
            app.MarkerSizeSpinner.Value = 5;

            % Create FaceColorButton
            app.FaceColorButton = uibutton(app.MarkerSettingsPanel, 'push');
            app.FaceColorButton.ButtonPushedFcn = createCallbackFcn(app, @FaceColorButtonPushed, true);
            app.FaceColorButton.Position = [18 11 80 22];
            app.FaceColorButton.Text = 'Face Color';

            % Create EdgeColorButton
            app.EdgeColorButton = uibutton(app.MarkerSettingsPanel, 'push');
            app.EdgeColorButton.ButtonPushedFcn = createCallbackFcn(app, @EdgeColorButtonPushed, true);
            app.EdgeColorButton.Position = [111 11 80 22];
            app.EdgeColorButton.Text = 'Edge Color';

            % Create TrailSettingsPanel
            app.TrailSettingsPanel = uipanel(app.BasicTab);
            app.TrailSettingsPanel.TitlePosition = 'centertop';
            app.TrailSettingsPanel.Title = 'Trail Settings';
            app.TrailSettingsPanel.BackgroundColor = [0.8 0.8 0.8];
            app.TrailSettingsPanel.FontWeight = 'bold';
            app.TrailSettingsPanel.Position = [11 89 211 128];

            % Create StyleDropDownLabel
            app.StyleDropDownLabel = uilabel(app.TrailSettingsPanel);
            app.StyleDropDownLabel.HorizontalAlignment = 'right';
            app.StyleDropDownLabel.Position = [14 72 28 22];
            app.StyleDropDownLabel.Text = 'Style';

            % Create StyleDropDown
            app.StyleDropDown = uidropdown(app.TrailSettingsPanel);
            app.StyleDropDown.ValueChangedFcn = createCallbackFcn(app, @StyleDropDownValueChanged, true);
            app.StyleDropDown.Position = [68 72 134 22];

            % Create SizeSpinner_2Label
            app.SizeSpinner_2Label = uilabel(app.TrailSettingsPanel);
            app.SizeSpinner_2Label.HorizontalAlignment = 'right';
            app.SizeSpinner_2Label.Position = [13 43 29 22];
            app.SizeSpinner_2Label.Text = 'Size';

            % Create TrailSizeSpinner
            app.TrailSizeSpinner = uispinner(app.TrailSettingsPanel);
            app.TrailSizeSpinner.Step = 0.1;
            app.TrailSizeSpinner.Limits = [1 Inf];
            app.TrailSizeSpinner.ValueChangedFcn = createCallbackFcn(app, @TrailSizeSpinnerValueChanged, true);
            app.TrailSizeSpinner.Position = [68 43 134 22];
            app.TrailSizeSpinner.Value = 1;

            % Create TrailColorButton
            app.TrailColorButton = uibutton(app.TrailSettingsPanel, 'push');
            app.TrailColorButton.ButtonPushedFcn = createCallbackFcn(app, @TrailColorButtonPushed, true);
            app.TrailColorButton.Position = [18 12 80 22];
            app.TrailColorButton.Text = 'Trail Color';

            % Create ClearTrailButton
            app.ClearTrailButton = uibutton(app.TrailSettingsPanel, 'push');
            app.ClearTrailButton.ButtonPushedFcn = createCallbackFcn(app, @ClearTrailButtonPushed, true);
            app.ClearTrailButton.Position = [111 12 80 22];
            app.ClearTrailButton.Text = 'Clear Trail';

            % Create MovementPanel
            app.MovementPanel = uipanel(app.BasicTab);
            app.MovementPanel.TitlePosition = 'centertop';
            app.MovementPanel.Title = 'Movement';
            app.MovementPanel.BackgroundColor = [0.8 0.8 0.8];
            app.MovementPanel.FontWeight = 'bold';
            app.MovementPanel.Position = [11 16 211 57];

            % Create StepEditFieldLabel
            app.StepEditFieldLabel = uilabel(app.MovementPanel);
            app.StepEditFieldLabel.HorizontalAlignment = 'right';
            app.StepEditFieldLabel.Position = [11 9 30 22];
            app.StepEditFieldLabel.Text = 'Step';

            % Create StepEditField
            app.StepEditField = uieditfield(app.MovementPanel, 'numeric');
            app.StepEditField.Limits = [0.001 Inf];
            app.StepEditField.Position = [66 9 134 22];
            app.StepEditField.Value = 0.1;

            % Create AdvancedTab
            app.AdvancedTab = uitab(app.TabGroup);
            app.AdvancedTab.Title = 'Advanced';

            % Create BoundarySettingsPanel
            app.BoundarySettingsPanel = uipanel(app.AdvancedTab);
            app.BoundarySettingsPanel.TitlePosition = 'centertop';
            app.BoundarySettingsPanel.Title = 'Boundary Settings';
            app.BoundarySettingsPanel.BackgroundColor = [0.8 0.8 0.8];
            app.BoundarySettingsPanel.FontWeight = 'bold';
            app.BoundarySettingsPanel.Position = [11 95 211 151];

            % Create BehaviorDropDownLabel
            app.BehaviorDropDownLabel = uilabel(app.BoundarySettingsPanel);
            app.BehaviorDropDownLabel.HorizontalAlignment = 'right';
            app.BehaviorDropDownLabel.Position = [12 103 52 22];
            app.BehaviorDropDownLabel.Text = 'Behavior';

            % Create BehaviorDropDown
            app.BehaviorDropDown = uidropdown(app.BoundarySettingsPanel);
            app.BehaviorDropDown.ValueChangedFcn = createCallbackFcn(app, @BehaviorDropDownValueChanged, true);
            app.BehaviorDropDown.Position = [78 103 121 22];

            % Create XDeltaEditFieldLabel
            app.XDeltaEditFieldLabel = uilabel(app.BoundarySettingsPanel);
            app.XDeltaEditFieldLabel.HorizontalAlignment = 'right';
            app.XDeltaEditFieldLabel.Position = [12 71 45 22];
            app.XDeltaEditFieldLabel.Text = 'X Delta';

            % Create XDeltaEditField
            app.XDeltaEditField = uieditfield(app.BoundarySettingsPanel, 'numeric');
            app.XDeltaEditField.Limits = [0.01 Inf];
            app.XDeltaEditField.Position = [66 71 131 22];
            app.XDeltaEditField.Value = 1;

            % Create YDeltaEditFieldLabel
            app.YDeltaEditFieldLabel = uilabel(app.BoundarySettingsPanel);
            app.YDeltaEditFieldLabel.HorizontalAlignment = 'right';
            app.YDeltaEditFieldLabel.Position = [12 39 45 22];
            app.YDeltaEditFieldLabel.Text = 'Y Delta';

            % Create YDeltaEditField
            app.YDeltaEditField = uieditfield(app.BoundarySettingsPanel, 'numeric');
            app.YDeltaEditField.Limits = [0.01 Inf];
            app.YDeltaEditField.Position = [66 39 131 22];
            app.YDeltaEditField.Value = 1;

            % Create ZDeltaEditFieldLabel
            app.ZDeltaEditFieldLabel = uilabel(app.BoundarySettingsPanel);
            app.ZDeltaEditFieldLabel.HorizontalAlignment = 'right';
            app.ZDeltaEditFieldLabel.Position = [14 7 44 22];
            app.ZDeltaEditFieldLabel.Text = 'Z Delta';

            % Create ZDeltaEditField
            app.ZDeltaEditField = uieditfield(app.BoundarySettingsPanel, 'numeric');
            app.ZDeltaEditField.Limits = [0.01 Inf];
            app.ZDeltaEditField.Position = [66 7 131 22];
            app.ZDeltaEditField.Value = 1;

            % Create InitialAxisLimitsPanel
            app.InitialAxisLimitsPanel = uipanel(app.AdvancedTab);
            app.InitialAxisLimitsPanel.TitlePosition = 'centertop';
            app.InitialAxisLimitsPanel.Title = 'Initial Axis Limits';
            app.InitialAxisLimitsPanel.BackgroundColor = [0.8 0.8 0.8];
            app.InitialAxisLimitsPanel.FontWeight = 'bold';
            app.InitialAxisLimitsPanel.Position = [11 253 211 116];

            % Create XLimitEditFieldLabel
            app.XLimitEditFieldLabel = uilabel(app.InitialAxisLimitsPanel);
            app.XLimitEditFieldLabel.HorizontalAlignment = 'right';
            app.XLimitEditFieldLabel.Position = [12 68 42 22];
            app.XLimitEditFieldLabel.Text = 'X Limit';

            % Create XLimitEditField
            app.XLimitEditField = uieditfield(app.InitialAxisLimitsPanel, 'numeric');
            app.XLimitEditField.Limits = [0.1 Inf];
            app.XLimitEditField.RoundFractionalValues = 'on';
            app.XLimitEditField.Position = [66 68 131 22];
            app.XLimitEditField.Value = 1;

            % Create YLimitEditFieldLabel
            app.YLimitEditFieldLabel = uilabel(app.InitialAxisLimitsPanel);
            app.YLimitEditFieldLabel.HorizontalAlignment = 'right';
            app.YLimitEditFieldLabel.Position = [12 37 42 22];
            app.YLimitEditFieldLabel.Text = 'Y Limit';

            % Create YLimitEditField
            app.YLimitEditField = uieditfield(app.InitialAxisLimitsPanel, 'numeric');
            app.YLimitEditField.Limits = [0.1 Inf];
            app.YLimitEditField.RoundFractionalValues = 'on';
            app.YLimitEditField.Position = [66 37 131 22];
            app.YLimitEditField.Value = 1;

            % Create ZLimitEditFieldLabel
            app.ZLimitEditFieldLabel = uilabel(app.InitialAxisLimitsPanel);
            app.ZLimitEditFieldLabel.HorizontalAlignment = 'right';
            app.ZLimitEditFieldLabel.Position = [12 6 41 22];
            app.ZLimitEditFieldLabel.Text = 'Z Limit';

            % Create ZLimitEditField
            app.ZLimitEditField = uieditfield(app.InitialAxisLimitsPanel, 'numeric');
            app.ZLimitEditField.Limits = [0.1 Inf];
            app.ZLimitEditField.Position = [66 6 131 22];
            app.ZLimitEditField.Value = 1;

            % Create AngleDistributionsettingsPanel
            app.AngleDistributionsettingsPanel = uipanel(app.AdvancedTab);
            app.AngleDistributionsettingsPanel.TitlePosition = 'centertop';
            app.AngleDistributionsettingsPanel.Title = 'Angle Distribution settings';
            app.AngleDistributionsettingsPanel.BackgroundColor = [0.8 0.8 0.8];
            app.AngleDistributionsettingsPanel.FontWeight = 'bold';
            app.AngleDistributionsettingsPanel.Position = [11 8 211 80];

            % Create DiscreteAngleDistributionCheckBox
            app.DiscreteAngleDistributionCheckBox = uicheckbox(app.AngleDistributionsettingsPanel);
            app.DiscreteAngleDistributionCheckBox.ValueChangedFcn = createCallbackFcn(app, @DiscreteAngleDistributionCheckBoxValueChanged, true);
            app.DiscreteAngleDistributionCheckBox.Text = 'Discrete Angle Distribution';
            app.DiscreteAngleDistributionCheckBox.Position = [14 31 161 22];

            % Create NumberofAngles2DEditFieldLabel
            app.NumberofAngles2DEditFieldLabel = uilabel(app.AngleDistributionsettingsPanel);
            app.NumberofAngles2DEditFieldLabel.HorizontalAlignment = 'right';
            app.NumberofAngles2DEditFieldLabel.Position = [13 7 125 22];
            app.NumberofAngles2DEditFieldLabel.Text = 'Number of Angles (2D)';

            % Create NumberofAngles2DEditField
            app.NumberofAngles2DEditField = uieditfield(app.AngleDistributionsettingsPanel, 'numeric');
            app.NumberofAngles2DEditField.Limits = [3 Inf];
            app.NumberofAngles2DEditField.RoundFractionalValues = 'on';
            app.NumberofAngles2DEditField.Enable = 'off';
            app.NumberofAngles2DEditField.Position = [155 7 43 22];
            app.NumberofAngles2DEditField.Value = 4;

            % Create ZEditFieldLabel
            app.ZEditFieldLabel = uilabel(app.UIFigure);
            app.ZEditFieldLabel.HorizontalAlignment = 'right';
            app.ZEditFieldLabel.Position = [369 37 25 22];
            app.ZEditFieldLabel.Text = 'Z';

            % Create ZEditField
            app.ZEditField = uieditfield(app.UIFigure, 'text');
            app.ZEditField.Editable = 'off';
            app.ZEditField.HorizontalAlignment = 'right';
            app.ZEditField.Enable = 'off';
            app.ZEditField.Position = [407 37 100 22];

            % Create DimensionRadio
            app.DimensionRadio = uibuttongroup(app.UIFigure);
            app.DimensionRadio.SelectionChangedFcn = createCallbackFcn(app, @DimensionRadioSelectionChanged, true);
            app.DimensionRadio.BorderType = 'none';
            app.DimensionRadio.TitlePosition = 'centertop';
            app.DimensionRadio.BackgroundColor = [0.9412 0.9412 0.9412];
            app.DimensionRadio.FontWeight = 'bold';
            app.DimensionRadio.Position = [598 70 133 30];

            % Create Radio2D
            app.Radio2D = uiradiobutton(app.DimensionRadio);
            app.Radio2D.Text = '2D';
            app.Radio2D.Position = [11 4 58 22];
            app.Radio2D.Value = true;

            % Create Radio3D
            app.Radio3D = uiradiobutton(app.DimensionRadio);
            app.Radio3D.Text = '3D';
            app.Radio3D.Position = [87 4 65 22];

            % Create ResetButton
            app.ResetButton = uibutton(app.UIFigure, 'push');
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);
            app.ResetButton.Position = [670 37 100 22];
            app.ResetButton.Text = 'Reset';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RandomWalk

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end