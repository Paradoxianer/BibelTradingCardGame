#ifndef CARD_H
#define CARD_H

#include <QList>
#include <QRect>
#include <QString>

#include "strength.h"
#include "action.h"
#include "cardstack.h"

class Card
{
public:
	Card();
	Card(QString *name,QString *verse,QString *scripture);

	QString* name(){return myName;}
    QString* verse(){return myVerse;}
    QString* scripture(){return myScripture;}

	void	layedOnCardStack(CardStack *stack);
	bool	onCardStack();
	void	takenFromCardStack();
	Card*	previosCard();
	Card*	nextCard();


private:
	QList<QRect>	provides;
	QList<Strength>	requires;
	QString			*myName;
	QString			*myVerse;
	QString			*myScripture;
	CardStack		*onStack;


};

#endif // CARD_H
