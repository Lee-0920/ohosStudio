/**
 * @file
 * @brief 阀映射图。
 * @details 
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */

#if !defined(CONTROLLER_API_VALVEMAP_H)
#define CONTROLLER_API_VALVEMAP_H

#include "CommunicationPlugin/Common/Types.h"

using System::Uint32;

namespace Controller
{
namespace API
{

/**
 * @brief 阀映射图。
 * @details 
 */
class ValveMap
{
public:
    ValveMap();
    ValveMap(Uint32 data);
    void SetData(Uint32 data);
    Uint32 GetData();
    void SetOn(int index);
    void SetOff(int index);
    bool IsOn(int index);
    void clear();
    void SetSpinValveCmd(Uint32 cmd, Uint32 Param1, Uint32 Param2);
    uint8_t GetCmd();
    uint8_t GetParam1();
    uint8_t GetParam2();
    Uint32 GetIndex();

private:
    Uint32 m_map;
    uint8_t m_cmd;
    uint8_t m_Param1;
    uint8_t m_Param2;

};

}
}

#endif  //CONTROLNET_API_VALVEMAP_H
