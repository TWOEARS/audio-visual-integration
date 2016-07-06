function playNotification ()

	file = getInfo('notification');

	[y, fs] = audioread(file);
	
    soundsc(y, fs);

end