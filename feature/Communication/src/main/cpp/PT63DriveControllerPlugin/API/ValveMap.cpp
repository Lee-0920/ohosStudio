/**
 * @file
 * @brief 阀映射图。
 * @details 
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */


#include "ValveMap.h"

namespace Controller
{
namespace API
{

ValveMap::ValveMap()
{

}

ValveMap::ValveMap(Uint32 data)
{
    m_map = data;
}

void ValveMap::SetData(Uint32 data)
{
    m_map = data;
}

Uint32 ValveMap::GetData()
{
    return m_map;
}

void ValveMap::SetOn(int index)
{
    m_map |= 1 << index;
}

void ValveMap::SetOff(int index)
{
    m_map &= ~(1 << index);
}

bool ValveMap::IsOn(int index)
{
    return (m_map & (1 << index));
}

void ValveMap::clear()
{
    m_map = 0;
    m_cmd = 0x00;
    m_Param1 = 0x00;
    m_Param2 = 0x00;
}

void ValveMap::SetSpinValveCmd(Uint32 cmd, Uint32 Param1, Uint32 Param2)
{
    m_cmd = (uint8_t)cmd;
    m_Param1 = (uint8_t)Param1;
    m_Param2 = (uint8_t)Param2;
}

uint8_t ValveMap::GetCmd()
{
    return m_cmd;
}

uint8_t ValveMap::GetParam1()
{
    return m_Param1;
}

uint8_t ValveMap::GetParam2()
{
    return m_Param2;
}

Uint32 ValveMap::GetIndex()
{
    Uint32 Valve = m_map;
    int index=0;
    for(index=0; index<32; index++)
    {
        if(Valve&0x00000001)
        {
            break;
        }
        Valve >>= 1;
    }
    return index+1;
}

}
}
