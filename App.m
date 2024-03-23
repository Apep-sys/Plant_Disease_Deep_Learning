classdef App < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        DiseaseDetectionUIFigure  matlab.ui.Figure
        BackgroundPanel           matlab.ui.container.Panel
        BackgroundAxes            matlab.ui.control.UIAxes
        TextArea                  matlab.ui.control.TextArea
        InsertPictureButton       matlab.ui.control.Button
        LanguageSwitch            matlab.ui.control.Switch
        InsertedImage             matlab.ui.control.Image
        PredictedPlantLabel       matlab.ui.control.Label
        DiseaseDetailsButton      matlab.ui.control.Button
        DiseaseNameMapping        containers.Map
        CurrentDiseaseEnglish     string
    end

    % Component initialization
    % Component initialization
    methods (Access = private)

    % Create UIFigure and components
    function createComponents(app)

        % Create DiseaseDetectionUIFigure
        app.DiseaseDetectionUIFigure = uifigure('Name', 'Disease Detection');
        app.DiseaseDetectionUIFigure.Position = [100 100 800 600]; % Set the figure position

        % Create BackgroundPanel
        app.BackgroundPanel = uipanel(app.DiseaseDetectionUIFigure);
        app.BackgroundPanel.BackgroundColor = [255/255, 228/255, 181/255];
        app.BackgroundPanel.Position = [1,1,834,604]; % Adjust the panel size

        % Create BackgroundAxes
        app.BackgroundAxes = uiaxes(app.BackgroundPanel);
        app.BackgroundAxes.Position = [1,1,834,604]; % Adjust the axes size
        imshow("D:\Downloads\imaginefundal.jpg", 'Parent', app.BackgroundAxes); % Set background image here
        app.BackgroundAxes.XTick = [];
        app.BackgroundAxes.YTick = [];
        app.BackgroundAxes.Box = 'off';

        % Create TextArea
        app.TextArea = uitextarea(app.DiseaseDetectionUIFigure);
        app.TextArea.Position = [320 510 160 35]; % Adjust position of TextArea
        app.TextArea.Value = {'  Choose the picture required for the inspection'};
        app.TextArea.Editable = false; % Make the text non-editable

        % Create InsertPictureButton
        app.InsertPictureButton = uibutton(app.DiseaseDetectionUIFigure, 'push');
        app.InsertPictureButton.Position = [320 470 160 35]; % Adjust position of InsertPictureButton
        app.InsertPictureButton.Text = 'Insert Picture';
        app.InsertPictureButton.ButtonPushedFcn = @(src, event) insertPictureButtonPushed(app);

        % Create LanguageSwitch
        app.LanguageSwitch = uiswitch(app.DiseaseDetectionUIFigure, 'slider');
        app.LanguageSwitch.Items = {'ENG', 'RO'};
        app.LanguageSwitch.Position = [50, 510, 50, 22]; % Adjust position of the switch button
        app.LanguageSwitch.ValueChangedFcn = @(src, event) switchLanguage(app, src, event);

        % Create PredictedPlantLabel
        app.PredictedPlantLabel = uilabel(app.DiseaseDetectionUIFigure);
        app.PredictedPlantLabel.Position = [320 440 400 22]; % Adjust position of PredictedPlantLabel
        app.PredictedPlantLabel.Text = '';

        % Create DiseaseDetailsButton
        app.DiseaseDetailsButton = uibutton(app.DiseaseDetectionUIFigure, 'push');
        app.DiseaseDetailsButton.Position = [320, 60, 160, 35]; % Adjust position of DiseaseDetailsButton
        app.DiseaseDetailsButton.Text = 'Disease Details';
        app.DiseaseDetailsButton.ButtonPushedFcn = @(src, event) DiseaseDetails(app);
        app.DiseaseDetailsButton.Visible = 'off'; % Set the button to be visible

        % Show the figure after all components are created
        app.DiseaseDetectionUIFigure.Visible = 'on';
    end


        % Function to add a border to an image
        function imgWithBorderPath = addImageBorder(~, imgPath, borderColor, borderWidth)
            img = imread(imgPath);
            % Create a border around the image
            border = uint8(ones(size(img, 1) + 2 * borderWidth, size(img, 2) + 2 * borderWidth, size(img, 3)) * 255);
            for c = 1:3
                border(:,:,c) = borderColor(c);
            end
            border(borderWidth+1:end-borderWidth, borderWidth+1:end-borderWidth, :) = img;
            % Convert the image with border to a format that can be used in the app
            imgWithBorderPath = [tempname, '.png'];
            imwrite(border, imgWithBorderPath);
        end

        function updateDiseaseLabelLanguage(app, language)
            % Check if the PredictedPlantLabel object exists and is valid
            if isempty(app.PredictedPlantLabel) || ~isvalid(app.PredictedPlantLabel)
                % If the label does not exist or is not valid, exit the function
                return;
            end
    
            % Now check if CurrentDiseaseEnglish has a valid value
            if isempty(app.CurrentDiseaseEnglish) || (~ischar(app.CurrentDiseaseEnglish) && ~isstring(app.CurrentDiseaseEnglish))
                % If there's no disease detected yet or the format is incorrect, exit the function
                return;
            end

            % Update the label based on the current language setting
            if language == "ENG"
                formattedLabel = strrep(app.CurrentDiseaseEnglish, '_', ' ');
                app.PredictedPlantLabel.Text = formattedLabel;
            elseif language == "RO"
                if isKey(app.DiseaseNameMapping, char(app.CurrentDiseaseEnglish))
                    app.PredictedPlantLabel.Text = app.DiseaseNameMapping(char(app.CurrentDiseaseEnglish));
                else
                    app.PredictedPlantLabel.Text = 'Boală necunoscută'; % Placeholder text for unknown disease
                end
            end
        end


         function insertPictureButtonPushed(app)
            % Open file explorer to select an image
            [fileName, pathName] = uigetfile({'*.jpg;*.jpeg;*.png'}, 'Select an image');
            if ~isequal(fileName, 0)
                % Clear the previous background image
                cla(app.BackgroundAxes); % Clear the current axes
                app.BackgroundAxes.Visible = 'on';
                app.BackgroundAxes.Color = [255/255, 228/255, 181/255];
                app.BackgroundAxes.Box = 'off';
                app.BackgroundAxes.XColor = 'none';
                app.BackgroundAxes.YColor = 'none'; 
                app.BackgroundAxes.XTick = [];
                app.BackgroundAxes.YTick = [];
        
                % Load pre-trained GoogLeNet
                net1 = googlenet;
                targetSize = net1.Layers(1).InputSize;
        
                imagePath = fullfile(pathName, fileName);
                inputImage = imread(imagePath);
                resizedImage = imresize(inputImage, targetSize(1:2));
        
                % Load your models
                load('plant_disease_model.mat', 'convnet');
        
                % Classify the image with the models
                [predictedLabel1, scores1] = classify(convnet, resizedImage);
               
                % Set confidence threshold for plant disease classification
                confidenceThreshold = 0.79; % Adjust as needed
        
                % Check if the highest confidence score from either model is above the threshold
                if max(scores1) >= confidenceThreshold 
                    disp(['Predicted label using Model 1: ' char(predictedLabel1)]);
                else
                    disp('The provided image is not recognized as a plant disease.');
                end
        
                disp('Max score for Model 1:');
                disp(max(scores1));
                
        
                % Add a green border to the image and get the new image path
                imgWithBorderPath = app.addImageBorder(imagePath, [0, 155, 0], 10); % Green border with a width of 10 pixels
        
                % Display the image with border
                app.InsertedImage = uiimage(app.DiseaseDetectionUIFigure);
                app.InsertedImage.ImageSource = imgWithBorderPath;
                imgWidth = size(resizedImage, 2);
                imgHeight = size(resizedImage, 1);
                app.InsertedImage.Position = [(app.DiseaseDetectionUIFigure.Position(3) - imgWidth) / 2, (app.DiseaseDetectionUIFigure.Position(4) - imgHeight) / 2 + 170, imgWidth, imgHeight]; % Adjust position and size of the inserted image to account for the border
        
                % Update the text with the predicted plant label
                app.PredictedPlantLabel = uilabel(app.DiseaseDetectionUIFigure);
                app.PredictedPlantLabel.Position = [app.InsertedImage.Position(1) + 30, app.InsertedImage.Position(2) - 30, 400, 22]; % Adjust position of the label
                if max(scores1) >= confidenceThreshold 
                    app.CurrentDiseaseEnglish = char(predictedLabel1);
                    updateDiseaseLabelLanguage(app, app.LanguageSwitch.Value);
                else
                    app.CurrentDiseaseEnglish = 'No disease detected';
                    updateDiseaseLabelLanguage(app, app.LanguageSwitch.Value);
                end
        
                % Make the Disease Details Button visible after picture is classified
                app.DiseaseDetailsButton.Visible = 'on';
        
                % Hide unnecessary components
                app.TextArea.Visible = 'off';
            end
        end


        function switchLanguage(app, src, ~)
            % Get the current value of the switch button
            selectedLanguage = src.Value;

            % Update the text of the components based on the selected language
            if strcmp(selectedLanguage, 'ENG')
                app.TextArea.Value = {'  Choose the picture required for the inspection'};
                app.InsertPictureButton.Text = 'Insert Picture';
                app.updateDiseaseLabelLanguage('ENG');
            elseif strcmp(selectedLanguage, 'RO')
                app.TextArea.Value = {'  Alegeți imaginea necesară pentru inspecție'};
                app.InsertPictureButton.Text = 'Inserați imaginea';
                app.updateDiseaseLabelLanguage('RO');
            end

            % Update the LanguageSwitch component text
            app.LanguageSwitch.Items = {'ENG', 'RO'}; % Update language options
        end


        function DiseaseDetails(app)
            % Check if there is a currently detected disease
        if ~isempty(app.CurrentDiseaseEnglish)
            % Get the details for the current disease
            details = app.getDiseaseDetails(app.CurrentDiseaseEnglish);

            % Display the details in a message box
            uialert(app.DiseaseDetectionUIFigure, details, 'Disease Details', 'Icon', 'info');
        else
            % If no disease is detected, show a message
            uialert(app.DiseaseDetectionUIFigure, 'No disease detected.', 'No Disease', 'Icon', 'info');
        end
    end


        function details = getDiseaseDetails(~, disease)
    % Define disease details based on the disease name
        diseaseDetails = {
    'Bacterial Spot (Pepper):'...
    '\n\tSmall, dark brown spots: Look for these spots on leaves and fruit. They may be surrounded by a yellow halo.'...
    '\n\tWater-soaked lesions: These sunken areas may appear on leaves and stems.'...
    '\n\tWilting and defoliation: In severe cases, leaves may wilt and fall off, affecting fruit production.'
    ,
    'Healthy Pepper Plant:'...
    '\n\tClean leaves: No spots or lesions should be visible on the leaves.'...
    '\n\tUpright stems: The stems should be strong and not wilting.'...
    '\n\tGood fruit development: Look for healthy, developing peppers without blemishes.'
    ,
    'Early Blight (Potato):'...
    '\n\tConcentric rings on leaves: Look for dark, brown rings getting progressively lighter towards the center.'...
    '\n\tShot holes: The centers of the brown rings may develop into holes in leaves.'...
    '\n\tStunted growth: Early blight can slow down potato plant growth and reduce yields.'
    ,
    'Healthy Potato Plant:'...
    '\n\tGreen, healthy leaves: No spots or lesions should be present on the leaves.'...
    '\n\tStrong stems: The stems should be upright and not wilting.'...
    '\n\tHealthy growth: The plant should be growing steadily with no signs of stunted development.'
    ,
    'Late Blight (Potato):'...
    '\n\tWater-soaked lesions: Look for dark, wet-looking areas on leaves and stems.'...
    '\n\tRapid spread: Late blight can quickly spread throughout a potato field.'...
    '\n\tBlight on tubers: In severe cases, the disease can infect the developing potatoes underground.'
    ,
    'Early Blight (Tomato):'...
    '\n\tConcentric rings on leaves: Similar to potato early blight, look for dark brown rings with lighter centers.'...
    '\n\tLeaf drop: As the disease progresses, leaves with blight may fall off.'...
    '\n\tReduced fruit production: Early blight can affect the overall yield of tomatoes.'
    ,
    'Late Blight (Tomato):'...
    '\n\tWater-soaked lesions: Look for dark, wet-looking areas on leaves, stems, and fruit.'...
    '\n\tRapid spread: Like potato late blight, this disease can quickly spread throughout a tomato field.'...
    '\n\tFruit rot: Late blight can cause infected tomatoes to rot and become unusable.'
    ,
    'Leaf Mold (Tomato):'...
    '\n\tYellow patches: Initially, the leaves develop yellow patches.'...
    '\n\tBrown spots: As the disease progresses, the yellow patches turn brown and may cover larger areas.'...
    '\n\tReduced fruit quality: Leaf mold can affect the overall health and quality of the developing tomatoes.'
    ,
    'Septoria Leaf Spot (Tomato):'...
    '\n\tSmall, dark spots: Look for these spots on leaves, with a yellow halo around them.'...
    '\n\tShot holes: The centers of the dark spots may develop into holes, creating a “shot-hole” effect.'...
    '\n\tDefoliation: In severe cases, heavy leaf loss can occur due to extensive infection.'
    ,
    'Spider Mites (Tomato):'...
    '\n\tYellow stippling: Look for a yellow, speckled appearance on the upper surface of leaves.'...
    '\n\tWebbing: Spider mites create fine webs on the underside of leaves.'...
    '\n\tLeaf drop: Heavy mite infestations can cause leaves to wilt and fall off.'
    ,
    'Target Spot (Tomato):'...
    '\n\tConcentric circles: Look for dark, brown circles with lighter centers on leaves and stems.'...
    '\n\tBulls-eye pattern: The concentric circles may resemble a bulls-eye target.'...
    '\n\tLeaf drop: Severely infected leaves may drop prematurely.'
    ,
    'Tomato Mosaic Virus:'...
    '\n\tDistorted leaves: The leaves become misshapen and develop a mosaic pattern of light and dark green areas.'...
    '\n\tStunted growth: The virus can slow down the growth of the tomato plant.'...
    '\n\tReduced fruit yield: The overall production of tomatoes may be significantly reduced.'
    ,
    'Tomato Yellow Leaf Curl Virus:'...
    '\n\tYellowing and curling: Leaves turn yellow and curl upwards at the edges.'...
    '\n\tBrittle leaves: Affected leaves become brittle and may crumble easily.'...
    '\n\tStunted growth: Similar to tomato mosaic virus, this virus can stunt the growth of the plant.'
    ,
    'Healthy Tomato Plant:'...
    '\n\tGreen, healthy leaves: No spots or lesions should be present on the leaves.'...
    '\n\tUpright stems: The stems should be strong and not wilting.'...
    '\n\tGood fruit development: Look for healthy, developing tomatoes without blemishes.'
};

    
    % Check if the disease name exists in the map
    if isKey(diseaseDetails, disease)
        details = diseaseDetails(disease);
    else
        details = 'No details available for this disease.';
    end
end


    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = App
            % Create UIFigure and components
            createComponents(app)
            % Register the app with App Designer
            registerApp(app, app.DiseaseDetectionUIFigure)
            
            % Mapam bolile
            englishNames = {'Pepper__bell___Bacterial_spot','Pepper__bell___healthy','Potato___Early_blight','Potato___healthy','Potato___Late_blight','Tomato_Early_blight','Tomato_Late_blight','Tomato_Leaf_Mold','Tomato_Septoria_leaf_spot','Tomato_Spider_mites_Two_spotted_spider_mite','Tomato__Target_Spot','Tomato__Tomato_mosaic_virus','Tomato__Tomato_YellowLeaf__Curl_Virus','Tomato_Bacterial_spot','Tomato_healthy'};
            romanianNames = {'Patarea frunzelor si basicarea fructelor de ardei','Ardei gras sanatos','Alternarioza la cartof','Cartof sanatos','Ciuperca Cartofului','Alternarioza tomatelor','Mana tomatelor','Patarea cafenie a frunzelor de tomate','Septorioza tomatelor','Paianjenul rosu comun','Pătarea brună a frunzelor de tomate','Mozaicul tomatelor','Virusul ingalbenirii si rasucirii frunzelor de tomate','Pătarea frunzelor și bășicarea fructelor tomatelor','Tomate sanatoase'};
            app.DiseaseNameMapping = containers.Map(englishNames, romanianNames);
        end

        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.DiseaseDetectionUIFigure)
        end
    end

end