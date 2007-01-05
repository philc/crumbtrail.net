
function toggleAppear(element){
	element=$(element);
	if (element.style && element.style.display=="none")
		Effect.Appear(element);

	else
		Effect.Fade(element);		
	return false;
}