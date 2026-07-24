#ifndef LOG_H
#define LOG_H

#include <string>
#include <fstream>
#include <mutex>
#include <vector>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <cstring>
#include <ctime>

class Logger {
public:
    static Logger* GetInstance();
    static void Init(const std::string& absolutePath);
    static std::string GetLogDir();
    
    // 日志写入
    void Debug(const std::string& msg);
    void Info(const std::string& msg);
    void Warn(const std::string& msg);
    void Error(const std::string& msg);
    
    // 可变参数版本
    void debug(const char* format, ...);
    void info(const char* format, ...);
    void warn(const char* format, ...);
    void error(const char* format, ...);
    
    // 辅助函数：格式化字符串
    static std::string FormatString(const char* format, va_list args);
    
    // 日志回读
    std::string ReadRecentLogs(int lines = 100);
    std::string ReadLogsFromFile(const std::string& fileName, int lines = 100);
    std::string ReadAllLogs(const std::string& fileName);
    
    // 文件信息
    struct LogFileInfo {
        std::string fileName;
        long fileSize;
        int lineCount;
        std::string lastModified;
    };
    LogFileInfo GetLogFileInfo(const std::string& fileName);
    std::vector<LogFileInfo> GetAllLogFilesInfo();
    
    // 文件操作
    bool ClearLogFile(const std::string& fileName);
    bool DeleteLogFile(const std::string& fileName);
    void Flush();

private:
    Logger() = default;
    ~Logger();
    
    static Logger* m_instance;
    static std::mutex m_mutex;
    static std::string m_logDir;
    
    void WriteLog(const std::string& level, const std::string& msg);
    void CheckAndRotate(const std::string& filePath);
    void WriteToFile(const std::string& filePath, const std::string& content);
    std::string GetCurrentTimestamp();
    bool CreateDirectory(const std::string& path);
    bool FileExists(const std::string& path);
    long GetFileSize(const std::string& path);
    void RotateFile(const std::string& filePath, int maxBackup);
};

#endif //LOG_H