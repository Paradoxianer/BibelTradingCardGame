#ifndef STRENGTH_H
#define STRENGTH_H

#include <QPoint>

class Strength
{
public:
    Strength(int  howMuch=1, QPoint there =QPoint(0,0), float howBig=1.0);
    QPoint  Where(){return where;};
    float   Size(){return size;};
    int     HowStrong(){return strenght;};
private:
    float   size;
    QPoint  where;
    int     strenght;
};

#endif // STRENGTH_H
