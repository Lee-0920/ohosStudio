#ifndef PT63DRIVECONTROLLERPLUGIN_H
#define PT63DRIVECONTROLLERPLUGIN_H

#include "Common/Types.h"
#include "ControllerPlugin/BaseController.h"
#include "ControllerPlugin/ControllerPlugin.h"

using System::String;

class PT63DriveController;

namespace Controller
{

class PT63DriveControllerPlugin : public ControllerPlugin
{

public:
    PT63DriveControllerPlugin();
    virtual ~PT63DriveControllerPlugin();
    bool Init();
    BaseController* Create(DscpAddress addr);
    PT63DriveController * GetDriveController();
    String GetVersion();

private:
    static PT63DriveController * m_dc;
};

// extern "C" 生成的导出符号没有任何修饰，方便主程序找到它
extern "C"
{
    ControllerPlugin *CreatePlugin();
}

}
#endif // PT63DRIVECONTROLLERPLUGIN_H

