import { VercelRequest, VercelResponse } from '@vercel/node';
import * as fs from 'fs';
import * as path from 'path';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    const cwd = process.cwd();
    const apiDir = path.join(cwd, 'api');
    const dataDir = path.join(cwd, 'data');
    const libDir = path.join(cwd, 'api', '_lib');
    
    // Check what directories exist
    const cwdExists = fs.existsSync(cwd);
    const apiExists = fs.existsSync(apiDir);
    const dataExists = fs.existsSync(dataDir);
    const libExists = fs.existsSync(libDir);
    
    // List contents of current directory
    let cwdContents: string[] = [];
    try {
      cwdContents = fs.readdirSync(cwd);
    } catch (e) {
      cwdContents = [`Error: ${e}`];
    }
    
    // List contents of data directory if it exists
    let dataContents: string[] = [];
    if (dataExists) {
      try {
        dataContents = fs.readdirSync(dataDir);
      } catch (e) {
        dataContents = [`Error: ${e}`];
      }
    }
    
    // List contents of api directory if it exists
    let apiContents: string[] = [];
    if (apiExists) {
      try {
        apiContents = fs.readdirSync(apiDir);
      } catch (e) {
        apiContents = [`Error: ${e}`];
      }
    }
    
    res.status(200).json({
      success: true,
      data: {
        cwd,
        paths: {
          api: apiDir,
          data: dataDir,
          lib: libDir
        },
        exists: {
          cwd: cwdExists,
          api: apiExists,
          data: dataExists,
          lib: libExists
        },
        contents: {
          cwd: cwdContents,
          data: dataContents,
          api: apiContents
        },
        __dirname,
        __filename: __filename || 'not available'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
}
