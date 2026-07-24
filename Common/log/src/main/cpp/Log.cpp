#include "Log.h"
#include <sstream>
#include <iostream>
#include <chrono>
#include <iomanip>
#include <cstdio>
#include <algorithm>
#include <cstdarg>
#include <vector>
#include <hilog/log.h> 

Logger* Logger::m_instance = nullptr;
std::mutex Logger::m_mutex;
std::string Logger::m_logDir;

Logger* Logger::GetInstance() {
    if (m_instance == nullptr) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_instance == nullptr) {
            m_instance = new Logger();
        }
    }
    return m_instance;
}

Logger::~Logger() {
}

bool Logger::CreateDirectory(const std::string& path) {
    if (path.empty()) return false;
    
    struct stat st;
    if (stat(path.c_str(), &st) == 0) {
        return S_ISDIR(st.st_mode);
    }
    
    size_t pos = path.find_last_of('/');
    if (pos != std::string::npos) {
        std::string parent = path.substr(0, pos);
        if (!CreateDirectory(parent)) return false;
    }
    
    return mkdir(path.c_str(), 0755) == 0;
}

bool Logger::FileExists(const std::string& path) {
    struct stat st;
    return stat(path.c_str(), &st) == 0 && S_ISREG(st.st_mode);
}

long Logger::GetFileSize(const std::string& path) {
    struct stat st;
    if (stat(path.c_str(), &st) == 0) {
        return st.st_size;
    }
    return 0;
}

std::string Logger::GetCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    
    std::tm tm;
    localtime_r(&time_t, &tm);
    
    std::ostringstream oss;
    oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S") << std::setfill('0') << std::setw(3);
    return oss.str();
}

void Logger::RotateFile(const std::string& filePath, int maxBackup) {
    // 删除最旧的备份
    std::string oldestBackup = filePath + "." + std::to_string(maxBackup);
    if (FileExists(oldestBackup)) {
        remove(oldestBackup.c_str());
    }
    
    // 依次重命名备份文件
    for (int i = maxBackup - 1; i >= 1; i--) {
        std::string oldFile = filePath + "." + std::to_string(i);
        std::string newFile = filePath + "." + std::to_string(i + 1);
        if (FileExists(oldFile)) {
            rename(oldFile.c_str(), newFile.c_str());
        }
    }
    
    // 将当前文件重命名为 .1
    if (FileExists(filePath)) {
        rename(filePath.c_str(), (filePath + ".1").c_str());
    }
}

void Logger::CheckAndRotate(const std::string& filePath) {
    const long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
    const int MAX_BACKUP = 5;
    
    if (FileExists(filePath) && GetFileSize(filePath) >= MAX_FILE_SIZE) {
        RotateFile(filePath, MAX_BACKUP);
    }
}

void Logger::WriteToFile(const std::string& filePath, const std::string& content) {
    std::lock_guard<std::mutex> lock(m_mutex);
    std::ofstream file(filePath, std::ios::app);
    if (file.is_open()) {
        file << content << std::endl;
        file.close();
    }
}

void Logger::WriteLog(const std::string& level, const std::string& msg) {
    std::string timestamp = GetCurrentTimestamp();
    std::string logContent = timestamp + " [" + level + "]: " + msg;
    
    // 写入 log.txt（所有日志）
    std::string logTxtPath = m_logDir + "log.txt";
    CheckAndRotate(logTxtPath);
    WriteToFile(logTxtPath, logContent);
    
    // 如果是 INFO 级别，额外写入 RunLog.txt
    if (level == "INFO") {
        std::string runLogPath = m_logDir + "RunLog.txt";
        CheckAndRotate(runLogPath);
        WriteToFile(runLogPath, logContent);
    }
}

void Logger::Init(const std::string& absolutePath) {
    m_logDir = absolutePath;
    
    if (GetInstance()->CreateDirectory(m_logDir)) {
        OH_LOG_INFO(LOG_APP, "created log directory at: %{public}s succeed", m_logDir.c_str());
    } else {
        OH_LOG_ERROR(LOG_APP, "created log directory at: %{public}s failed", m_logDir.c_str());
    }
}

std::string Logger::GetLogDir() {
    return m_logDir;
}

void Logger::Debug(const std::string& msg) {
    WriteLog("DEBUG", msg);
}

void Logger::Info(const std::string& msg) {
    WriteLog("INFO", msg);
}

void Logger::Warn(const std::string& msg) {
    WriteLog("WARN", msg);
}

void Logger::Error(const std::string& msg) {
    WriteLog("ERROR", msg);
}

void Logger::Flush() {
    // 同步写入已通过 WriteToFile 中的锁保证，无需额外操作
}

// ========== 日志回读实现 ==========

std::string Logger::ReadRecentLogs(int lines) {
    return ReadLogsFromFile("log.txt", lines);
}

std::string Logger::ReadLogsFromFile(const std::string& fileName, int lines) {
    std::string filePath = m_logDir + fileName;
    
    if (!FileExists(filePath)) {
        return "";
    }
    
    std::lock_guard<std::mutex> lock(m_mutex);
    std::ifstream file(filePath);
    if (!file.is_open()) {
        return "";
    }
    
    std::vector<std::string> allLines;
    std::string line;
    while (std::getline(file, line)) {
        allLines.push_back(line);
    }
    file.close();
    
    int totalLines = allLines.size();
    int startLine = totalLines > lines ? totalLines - lines : 0;
    
    std::string result;
    for (int i = startLine; i < totalLines; i++) {
        result += allLines[i] + "\n";
    }
    
    return result;
}

std::string Logger::ReadAllLogs(const std::string& fileName) {
    std::string filePath = m_logDir + fileName;
    
    if (!FileExists(filePath)) {
        return "";
    }
    
    std::lock_guard<std::mutex> lock(m_mutex);
    std::ifstream file(filePath);
    if (!file.is_open()) {
        return "";
    }
    
    std::string content;
    std::string line;
    while (std::getline(file, line)) {
        content += line + "\n";
    }
    file.close();
    
    return content;
}

Logger::LogFileInfo Logger::GetLogFileInfo(const std::string& fileName) {
    LogFileInfo info;
    info.fileName = fileName;
    
    std::string filePath = m_logDir + fileName;
    
    if (!FileExists(filePath)) {
        info.fileSize = 0;
        info.lineCount = 0;
        info.lastModified = "";
        return info;
    }
    
    info.fileSize = GetFileSize(filePath);
    
    struct stat st;
    if (stat(filePath.c_str(), &st) == 0) {
        std::time_t modTime = st.st_mtime;
        std::tm tm;
        localtime_r(&modTime, &tm);
        std::ostringstream oss;
        oss << std::put_time(&tm, "%Y-%m-%d %H:%M:%S");
        info.lastModified = oss.str();
    }
    
    std::lock_guard<std::mutex> lock(m_mutex);
    std::ifstream file(filePath);
    if (file.is_open()) {
        std::string line;
        info.lineCount = 0;
        while (std::getline(file, line)) {
            info.lineCount++;
        }
        file.close();
    }
    
    return info;
}

std::vector<Logger::LogFileInfo> Logger::GetAllLogFilesInfo() {
    std::vector<LogFileInfo> result;
    
    // 检查 log.txt 及其备份
    for (int i = 0; i <= 5; i++) {
        std::string fileName = (i == 0) ? "log.txt" : "log.txt." + std::to_string(i);
        if (FileExists(m_logDir + fileName)) {
            result.push_back(GetLogFileInfo(fileName));
        }
    }
    
    // 检查 RunLog.txt 及其备份
    for (int i = 0; i <= 5; i++) {
        std::string fileName = (i == 0) ? "RunLog.txt" : "RunLog.txt." + std::to_string(i);
        if (FileExists(m_logDir + fileName)) {
            result.push_back(GetLogFileInfo(fileName));
        }
    }
    
    // 按文件名排序
    std::sort(result.begin(), result.end(), [](const LogFileInfo& a, const LogFileInfo& b) {
        return a.fileName < b.fileName;
    });
    
    return result;
}

bool Logger::ClearLogFile(const std::string& fileName) {
    std::string filePath = m_logDir + fileName;
    if (FileExists(filePath)) {
        std::lock_guard<std::mutex> lock(m_mutex);
        std::ofstream file(filePath, std::ios::trunc);
        if (file.is_open()) {
            file.close();
            return true;
        }
        return false;
    }
    return false;
}

bool Logger::DeleteLogFile(const std::string& fileName) {
    std::string filePath = m_logDir + fileName;
    if (FileExists(filePath)) {
        std::lock_guard<std::mutex> lock(m_mutex);
        return remove(filePath.c_str()) == 0;
    }
    return false;
}

// 格式化字符串的实现
std::string Logger::FormatString(const char* format, va_list args) {
    // 第一次调用：计算需要的大小
    va_list args_copy;
    va_copy(args_copy, args);
    int size = vsnprintf(nullptr, 0, format, args_copy);
    va_end(args_copy);
    
    if (size <= 0) {
        return "";
    }
    
    // 分配缓冲区并格式化
    std::vector<char> buffer(size + 1);
    vsnprintf(buffer.data(), buffer.size(), format, args);
    
    return std::string(buffer.data());
}

// 可变参数版本实现
void Logger::debug(const char* format, ...) {
    va_list args;
    va_start(args, format);
    std::string msg = FormatString(format, args);
    va_end(args);
    Debug(msg);  // 调用原有的 Debug 方法
}

void Logger::info(const char* format, ...) {
    va_list args;
    va_start(args, format);
    std::string msg = FormatString(format, args);
    va_end(args);
    Info(msg);   // 调用原有的 Info 方法
}

void Logger::warn(const char* format, ...) {
    va_list args;
    va_start(args, format);
    std::string msg = FormatString(format, args);
    va_end(args);
    Warn(msg);   // 调用原有的 Warn 方法
}

void Logger::error(const char* format, ...) {
    va_list args;
    va_start(args, format);
    std::string msg = FormatString(format, args);
    va_end(args);
    Error(msg);  // 调用原有的 Error 方法
}