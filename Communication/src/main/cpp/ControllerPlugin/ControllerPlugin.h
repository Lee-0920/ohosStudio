#ifndef CONTROLLERPLUGIN_H
#define CONTROLLERPLUGIN_H

#include "Common/Types.h"
#include "BaseController.h"

using System::String;

namespace Controller
{

class ControllerPlugin
{
public:
    ControllerPlugin();
    virtual ~ControllerPlugin();
    virtual bool Init();
    virtual BaseController* Create(DscpAddress addr);
    virtual String GetVersion();  
};

}
#endif // CONTROLLERPLUGIN_H
