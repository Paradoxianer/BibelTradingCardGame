#ifndef ACTION_H
#define ACTION_H

#include <QList>
#include "game.h"

class Card;

class Action
{
public:
			Action(Card *fromCard, Game *forGame);
    void    Init(void);
    void    AddSourceCard(Card *fromCard);
    void    RemoveSourceCard(Card *fromCard);

	void	Do(QList<Card> *targetCards);
	void	Do(Card    *targetCard);

private:
	QList<Card*> *source;
	QList<Card*> *target;
	Game		*universe;
};

#endif // ACTION_H
