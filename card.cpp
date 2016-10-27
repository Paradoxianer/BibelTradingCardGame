#include "card.h"

Card::Card()
{
	Init();
}

Card::Card(QString *name, QString *verse, QString *scripture)
{
	Init();
}

void Card::Init()
{
	provides	= new QList<QRect>();
	requires	= new QList<Strength>();
	myName		= NULL;
	myVerse		= NULL;
	myScripture	= NULL;
	onStack		= NULL;
}

