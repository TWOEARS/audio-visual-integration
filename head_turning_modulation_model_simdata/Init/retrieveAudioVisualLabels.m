function [AVPairs_labels, audio_labels, visual_labels] = retrieveAudioVisualLabels ()


	AVPairs_file = xmlread('AVPairs.xml');
    AVPairs = AVPairs_file.getElementsByTagName('pair');

    nb_AVPairs = AVPairs.getLength();

    AVPairs_labels = cell(nb_AVPairs, 1);

    audio_labels = cell(0);
    visual_labels = cell(0);

    for iPair = 0:nb_AVPairs-1
        pair = AVPairs.item(iPair);
        % read the visual category
        visual_label = char(pair.getAttribute('A'));
        audio_label = char(pair.getAttribute('B'));

        if isempty(audio_labels)
            audio_labels{end+1} = audio_label;
        % elseif ~strcmp(audio_label, audio_labels{end})
        elseif ~strcmp(audio_label, audio_labels)
            audio_labels{end+1} = audio_label;
        end
            
        if isempty(visual_labels)
            visual_labels{end+1} = visual_label;
        % elseif ~strcmp(visual_label, visual_labels{end})
        elseif ~strcmp(visual_label, visual_labels)
            visual_labels{end+1} = visual_label;
        end
        AVPairs_labels{iPair+1} = {visual_label, audio_label};
    end

    % setappdata(0, 'AVPairs', AVPairs_labels) ;
    % setappdata(0, 'audio_labels', unique(audio_labels)) ;
    % setappdata(0, 'visual_labels', unique(visual_labels)) ;

end