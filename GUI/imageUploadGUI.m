function imageUploadGUI
    % Create the main figure window with custom title and size
    fig = uifigure('Name', 'Image Upload Interface', 'Position', [100 100 800 600], 'Color', [0.9 0.9 0.9]);

    % Create a panel for elastography options
    elastographyPanel = uipanel(fig, 'Position', [20, 560, 610, 70], 'Title', 'Elastography Options', 'Visible', 'off', 'FontSize', 12, 'BackgroundColor', [0.95 0.95 0.95]);

    % Create buttons for elastography options
    createElastographyButtons(elastographyPanel, fig); % Pass fig for storing data in appdata

    % Create a panel for coordinate input (smaller, around 90% of original width)
    coordPanel = uipanel(fig, 'Position', [640, 560, 0.9 * 150, 70], 'Title', 'Masking Region', 'Visible', 'off', 'FontSize', 12, 'BackgroundColor', [0.95 0.95 0.95]);
    
    % Create input fields for x0, x1, y0, y1
    uilabel(coordPanel, 'Text', 'x0:', 'Position', [10, 20, 20, 20]);
    x0Field = uieditfield(coordPanel, 'numeric', 'Position', [30, 20, 30, 20], 'Value', 1);
    uilabel(coordPanel, 'Text', 'x1:', 'Position', [70, 20, 20, 20]);
    x1Field = uieditfield(coordPanel, 'numeric', 'Position', [90, 20, 30, 20]);
    uilabel(coordPanel, 'Text', 'y0:', 'Position', [130, 20, 20, 20]);
    y0Field = uieditfield(coordPanel, 'numeric', 'Position', [150, 20, 30, 20], 'Value', 1);
    uilabel(coordPanel, 'Text', 'y1:', 'Position', [190, 20, 20, 20]);
    y1Field = uieditfield(coordPanel, 'numeric', 'Position', [210, 20, 30, 20]);
    
    % Create a panel for kernel_size parameter input (new panel)
    paramPanel = uipanel(fig, 'Position', [785, 560, 100, 70], 'Title', 'Kernel Size and std', 'Visible', 'off', 'FontSize', 12, 'BackgroundColor', [0.95 0.95 0.95]);
    
    % Create input field for kappa (k)
    uilabel(paramPanel, 'Text', '$\kappa$:', 'Position', [10, 20, 40, 20], 'Interpreter', 'latex');
    kappaField = uieditfield(paramPanel, 'numeric', 'Position', [30, 20, 30, 20]);

    uilabel(paramPanel, 'Text', '$\sigma$:', 'Position', [70, 20, 20, 20], 'Interpreter', 'latex');
    sigmaField = uieditfield(paramPanel, 'numeric', 'Position', [90, 20, 30, 20]);

    % Create a panel for the image viewer
    imageViewerPanel = uipanel(fig, 'Position', [95 100 710 450], 'Title', 'Image Viewer', 'FontSize', 14, 'BackgroundColor', [0.95 0.95 0.95]);

    % Create axes for displaying images
    ax1 = uiaxes(imageViewerPanel, 'Position', [35, 50, 300, 300], 'Box', 'on', 'XColor', 'none', 'YColor', 'none');
    ax2 = uiaxes(imageViewerPanel, 'Position', [375, 50, 300, 300], 'Box', 'on', 'XColor', 'none', 'YColor', 'none');

    % Initialize variables to store images and flow components
    img1 = [];
    img2 = [];
    u = [];
    v = [];

    % Initialize strain variables as persistent
    persistent absstrain shearstrain normalstrain vorticity vonmises uflow vflow; 

    % Create the upload button for images
    btnUploadImages = uibutton(fig, 'push', 'Text', 'Upload Baseline', ...
        'Position', [350, 40, 150, 30], ...
        'FontSize', 14, ...
        'BackgroundColor', [0.2 0.6 0.8], ...
        'ButtonPushedFcn', @(btn, event) uploadImage(btn, ax1, ax2));

    % Create the upload button for the .flo file (initially hidden)
    btnUploadFlo = uibutton(fig, 'push', 'Text', 'Upload .flo File', ...
        'Position', [350, 20, 150, 30], ...
        'FontSize', 14, ...
        'BackgroundColor', [0.8 0.2 0.2], ...
        'Visible', 'off', ...
        'ButtonPushedFcn', @(btn, event) uploadFlo(btn));

    % Create the visualize button (initially hidden)
    btnVisualize = uibutton(fig, 'push', 'Text', 'Visualize Elastography', ...
        'Position', [520, 20, 150, 30], ...
        'FontSize', 14, ...
        'BackgroundColor', [0.8 0.2 0.2], ...
        'Visible', 'off', ...
        'ButtonPushedFcn', @(btn, event) visualizeElastography());

    % Store the fields in the appdata for later access
    setappdata(fig, 'x0Field', x0Field);
    setappdata(fig, 'x1Field', x1Field);
    setappdata(fig, 'y0Field', y0Field);
    setappdata(fig, 'y1Field', y1Field);
    setappdata(fig, 'kappaField', kappaField);
    setappdata(fig, 'sigmaField', sigmaField);

    % Nested function to handle the image upload
    function uploadImage(btn, ax1, ax2)
        persistent lastPath; % Store the last accessed folder
        if isempty(lastPath)
            lastPath = pwd; % Default to current directory
        end
    
        % Open file dialog with the last accessed folder
        [file, path] = uigetfile({'*.png;*.jpg;*.jpeg;*.tiff', 'Image Files'}, 'Select an Image', lastPath);
        if isequal(file, 0)
            return; % User canceled the operation
        end
    
        % Update the last accessed folder
        lastPath = path;
    
        % Read and display the image
        imgPath = fullfile(path, file);
        img = imread(imgPath);
    
        % Check the current button text to determine which image to upload
        if strcmp(btn.Text, 'Upload Baseline')
            img1 = img; % Store the first image
            imshow(img1, 'Parent', ax1); % Display image 1 in the first axes
            title(ax1, 'Image 1', 'FontSize', 12, 'FontWeight', 'bold');
            btn.Text = 'Upload Followup'; % Change the button text
            btn.BackgroundColor = [0.8 0.6 0.2]; % Change the button color for second image
        elseif strcmp(btn.Text, 'Upload Followup')
            img2 = img; % Store the second image
            imshow(img2, 'Parent', ax2); % Display image 2 in the second axes
            title(ax2, 'Image 2', 'FontSize', 12, 'FontWeight', 'bold');
            btn.Text = 'Images Uploaded'; % Change the button text to indicate completion
            btn.Enable = 'off'; % Make the button inactive
            btnUploadFlo.Visible = 'on'; % Show the .flo upload button
            btn.BackgroundColor = [0.2 0.8 0.2]; % Change the button color for uploaded images
        end
    end

    % Nested function to handle the .flo file upload
    function uploadFlo(btn)
        persistent lastPath; % Store the last accessed folder
        if isempty(lastPath)
            lastPath = pwd; % Default to current directory
        end

        % [file, path] = uigetfile({'*.flo', 'Flow Files'}, 'Select a .flo File', lastPath);
        % if isequal(file, 0)
        %     return; % User canceled the operation
        % end
        % 
        % % Read the .flo file
        % floPath = fullfile(path, file);
        % [u, v] = readFloFile(floPath); % Read the flow components
        [file, path] = uigetfile({'*.flo;*.mat', 'Flow and MAT Files'}, 'Select a .flo or .mat File', lastPath);
        if isequal(file, 0)
            return; % User canceled the operation
        end
        
        % Construct the full file path
        filePath = fullfile(path, file);
        
        % Check the file extension and read accordingly
        [~, ~, ext] = fileparts(filePath); % Get the file extension
        
        if strcmp(ext, '.flo')
            % Read the .flo file
            [u, v] = readFlowFile(filePath); % Read the flow components
            %u = (u - min(min(u)) )/max(max(u));
            %v = (v - min(min(v)) )/max(max(v));
        elseif strcmp(ext, '.mat')
            flow = load(filePath);
            flow = flow.Disp_field_1;
            u = flow(:,:,1);
            v = flow(:,:,2);
        end

        % Enable the visualization button
        btnVisualize.Visible = 'on'; % Show the visualize button
        btnUploadFlo.Visible = 'off'; % Hide the .flo upload button
    end

    % Nested function to visualize the elastography
    function visualizeElastography()
        % Call the external elastography function to compute strain
        handles = elastography();

        persistent initialKappa;

        if isempty(initialKappa)
            disp('Welcome!');
            initialKappa = 15;  % Set initial kappa value only once
            kappaField.Value = initialKappa;  % Assign to UI field
        end

        persistent initialsigma;
        if isempty(initialsigma)
            initialsigma = 5;  % Set initial sigma value only once
            sigmaField.Value = initialsigma;  % Assign to UI field
        end

        k = kappaField.Value; %kernel size
        sigma = sigmaField.Value; %sigma value

        [exx, eyy, exy, ~, ~, mag] = handles.strain_from_uv_flow(u, v, sigma, k);
        [von] = handles.vonMissesCoefficient(u, v, sigma, k);
        [w] = handles.vorticity_from_uv_flow(u, v, sigma, k);
        absstrain = mag;
        normalstrain = sqrt(exx.^2 + eyy.^2);
        shearstrain = sqrt(exy.^2 + exy.^2);
        uflow = u;
        vflow = v;
        vorticity = w;
        vonmises = von;
        
        % Check if the strain matrices are valid
        if ~isempty(absstrain) && ~isempty(shearstrain) && ~isempty(normalstrain) && ~isempty(u) && ~isempty(v) && ~isempty(vorticity)
            % Store the strain matrices for access in other functions
            assignin('base', 'absolutestrain', absstrain);
            assignin('base', 'normalstrain', normalstrain);
            assignin('base', 'shearstrain', shearstrain);
            assignin('base', 'vorticity', vorticity);
            assignin('base', 'vonmises', vonmises);
            assignin('base', 'uflow', uflow);
            assignin('base', 'vflow', vflow);

            [height, width] = size(uflow);
            y1Field.Value = height;
            x1Field.Value = width;
            
            % Display the elastography options panel
            elastographyPanel.Visible = 'on';
            coordPanel.Visible = 'on'; 
            paramPanel.Visible = 'on';
        else
            uialert(fig, 'Error: Strain matrices are empty. Please check the inputs.', 'Input Error');
        end
    end

    % Function to create elastography buttons
    function createElastographyButtons(parentPanel, fig)
        buttonLabels = {'AbsoluteStrain', 'ShearStrain', 'NormalStrain', 'Vorticity', 'vonMises', 'UFlow', 'VFlow'};
        buttonColors = {[0.8 0.4 0.4], [0.4 0.8 0.4], [0.4 0.4 0.8], [0.8 0.8 0.4], [0.4 0.8 0.8], [0.8 0.4 0.8], [0.8 0.8 0.8]};
        
        for i = 1:length(buttonLabels)
            % Create each button
            uibutton(parentPanel, 'push', ...
                'Text', buttonLabels{i}, ...
                'Position', [18 + (i - 1) * 85, 6, 75, 40], ...
                'FontSize', 10, ...
                'BackgroundColor', buttonColors{i}, ...
                'ButtonPushedFcn', @(btn, event) showElastographyParameter(buttonLabels{i}, getappdata(fig, 'x0Field').Value, getappdata(fig, 'x1Field').Value, getappdata(fig, 'y0Field').Value, getappdata(fig, 'y1Field').Value));
        end
    end


end
