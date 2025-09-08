// api/_lib/logger.ts
import { env } from './env';

export interface Logger {
  trace(message: string, data?: any): void;
  debug(message: string, data?: any): void;
  info(message: string, data?: any): void;
  warn(message: string, data?: any): void;
  error(message: string, data?: any): void;
  fatal(message: string, data?: any): void;
  child(bindings: Record<string, any>): Logger;
}

interface LoggerConfig {
  level: string;
  service: string;
  env: string;
  version: string;
  pretty: boolean;
}

class ConsoleLogger implements Logger {
  private config: LoggerConfig;
  private bindings: Record<string, any>;

  constructor(config?: Partial<LoggerConfig>, bindings: Record<string, any> = {}) {
    this.config = {
      level: process.env.LOG_LEVEL || 'info',
      service: 'unsaid-api',
      env: env.NODE_ENV,
      version: process.env.SERVICE_VERSION || '0.0.0',
      pretty: env.NODE_ENV !== 'production' || process.env.PRETTY_LOGS === '1',
      ...config
    };
    this.bindings = bindings;
  }

  private shouldLog(level: string): boolean {
    const levels = ['trace', 'debug', 'info', 'warn', 'error', 'fatal'];
    const currentLevelIndex = levels.indexOf(this.config.level);
    const messageLevelIndex = levels.indexOf(level);
    return messageLevelIndex >= currentLevelIndex;
  }

  private log(level: string, message: string, data?: any): void {
    if (!this.shouldLog(level)) return;
    
    const timestamp = new Date().toISOString();
    const logEntry = {
      timestamp,
      level: level.toUpperCase(),
      service: this.config.service,
      env: this.config.env,
      version: this.config.version,
      message,
      ...this.bindings,
      ...(data && typeof data === 'object' ? data : { data })
    };

    if (this.config.pretty) {
      // Pretty format for development
      const contextStr = Object.keys(this.bindings).length > 0 
        ? ` [${Object.entries(this.bindings).map(([k, v]) => `${k}=${v}`).join(', ')}]` 
        : '';
      const dataStr = data ? ` ${JSON.stringify(data, null, 2)}` : '';
      console.log(`[${timestamp}] ${level.toUpperCase()}${contextStr}: ${message}${dataStr}`);
    } else {
      // Structured JSON for production
      console.log(JSON.stringify(logEntry));
    }
  }

  trace(message: string, data?: any): void {
    this.log('trace', message, data);
  }

  debug(message: string, data?: any): void {
    this.log('debug', message, data);
  }

  info(message: string, data?: any): void {
    this.log('info', message, data);
  }

  warn(message: string, data?: any): void {
    this.log('warn', message, data);
  }

  error(message: string, data?: any): void {
    this.log('error', message, data);
  }

  fatal(message: string, data?: any): void {
    this.log('fatal', message, data);
  }

  // Create child logger with additional context (matching JavaScript version)
  child(bindings: Record<string, any>): Logger {
    return new ConsoleLogger(this.config, { ...this.bindings, ...bindings });
  }
}

// Create base logger instance
export const logger: Logger = new ConsoleLogger();

// Helper function to create module-specific loggers (matching JavaScript version)
export function withModule(moduleName: string, extra: Record<string, any> = {}): Logger {
  return logger.child({ module: moduleName, ...extra });
}

// Generate stable ID (matching JavaScript version)
export function genId(prefix: string = 'id'): string {
  return `${prefix}_${Date.now().toString(36)}_${Math.random().toString(36).substring(2)}`;
}
