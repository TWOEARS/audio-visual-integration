function request = generateEmptyVector ()

	a = getInfo('nb_audio_labels');
	v = getInfo('nb_visual_labels');

    request = zeros(a+v, 1);
end