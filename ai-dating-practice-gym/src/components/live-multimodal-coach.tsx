"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import { buildLiveFeedback, type LiveMultimodalMetrics } from "@/lib/live-feedback";

type FaceLike = {
  boundingBox?: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
};

type FaceDetectorLike = {
  detect: (input: HTMLVideoElement) => Promise<FaceLike[]>;
};

type WindowWithFaceDetector = Window & {
  FaceDetector?: new (options?: unknown) => FaceDetectorLike;
};

type Counters = {
  sampleCount: number;
  speakingSamples: number;
  volumeTotal: number;
  highVolumeSamples: number;
  faceChecks: number;
  faceDetectedSamples: number;
  centeredFaceSamples: number;
  motionTotal: number;
};

const FRAME_WIDTH = 96;
const FRAME_HEIGHT = 72;

const defaultMetrics: LiveMultimodalMetrics = {
  elapsedSeconds: 0,
  sampleCount: 0,
  speakingRatio: 0,
  avgVolume: 0,
  highVolumeRatio: 0,
  facePresenceRatio: null,
  centeredFaceRatio: null,
  motionScore: 0,
};

function toFixed(value: number, decimals = 2) {
  return Number(value.toFixed(decimals));
}

function calculateMetrics(
  counters: Counters,
  elapsedSeconds: number,
  faceDetectionAvailable: boolean,
): LiveMultimodalMetrics {
  if (counters.sampleCount === 0) {
    return {
      ...defaultMetrics,
      elapsedSeconds,
      facePresenceRatio: faceDetectionAvailable ? 0 : null,
      centeredFaceRatio: faceDetectionAvailable ? 0 : null,
    };
  }

  return {
    elapsedSeconds,
    sampleCount: counters.sampleCount,
    speakingRatio: toFixed(counters.speakingSamples / counters.sampleCount, 3),
    avgVolume: toFixed(counters.volumeTotal / counters.sampleCount, 3),
    highVolumeRatio: toFixed(counters.highVolumeSamples / counters.sampleCount, 3),
    facePresenceRatio:
      faceDetectionAvailable && counters.faceChecks > 0
        ? toFixed(counters.faceDetectedSamples / counters.faceChecks, 3)
        : null,
    centeredFaceRatio:
      faceDetectionAvailable && counters.faceChecks > 0
        ? toFixed(counters.centeredFaceSamples / counters.faceChecks, 3)
        : null,
    motionScore: toFixed(counters.motionTotal / counters.sampleCount, 3),
  };
}

export function LiveMultimodalCoach() {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const faceDetectorRef = useRef<FaceDetectorLike | null>(null);
  const analysisTimerRef = useRef<number | null>(null);
  const elapsedTimerRef = useRef<number | null>(null);
  const sampleBusyRef = useRef(false);
  const runningRef = useRef(false);
  const startTimeRef = useRef<number | null>(null);
  const countersRef = useRef<Counters>({
    sampleCount: 0,
    speakingSamples: 0,
    volumeTotal: 0,
    highVolumeSamples: 0,
    faceChecks: 0,
    faceDetectedSamples: 0,
    centeredFaceSamples: 0,
    motionTotal: 0,
  });
  const previousFrameRef = useRef<Uint8ClampedArray | null>(null);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const contextRef = useRef<CanvasRenderingContext2D | null>(null);

  const [running, setRunning] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [faceDetectionAvailable, setFaceDetectionAvailable] = useState(false);
  const [metrics, setMetrics] = useState<LiveMultimodalMetrics>(defaultMetrics);

  const insights = useMemo(
    () => buildLiveFeedback({ metrics, faceDetectionAvailable }),
    [metrics, faceDetectionAvailable],
  );

  const getElapsedSeconds = useCallback(() => {
    if (!startTimeRef.current) {
      return 0;
    }
    return Math.floor((Date.now() - startTimeRef.current) / 1000);
  }, []);

  const clearTimers = useCallback(() => {
    if (analysisTimerRef.current !== null) {
      window.clearInterval(analysisTimerRef.current);
      analysisTimerRef.current = null;
    }
    if (elapsedTimerRef.current !== null) {
      window.clearInterval(elapsedTimerRef.current);
      elapsedTimerRef.current = null;
    }
  }, []);

  const resetCounters = useCallback(() => {
    countersRef.current = {
      sampleCount: 0,
      speakingSamples: 0,
      volumeTotal: 0,
      highVolumeSamples: 0,
      faceChecks: 0,
      faceDetectedSamples: 0,
      centeredFaceSamples: 0,
      motionTotal: 0,
    };
    previousFrameRef.current = null;
    setMetrics(defaultMetrics);
  }, []);

  const measureMotion = useCallback((video: HTMLVideoElement) => {
    if (!canvasRef.current) {
      canvasRef.current = document.createElement("canvas");
      canvasRef.current.width = FRAME_WIDTH;
      canvasRef.current.height = FRAME_HEIGHT;
      contextRef.current = canvasRef.current.getContext("2d", {
        willReadFrequently: true,
      });
    }

    const context = contextRef.current;
    if (!context) {
      return 0;
    }

    context.drawImage(video, 0, 0, FRAME_WIDTH, FRAME_HEIGHT);
    const current = context.getImageData(0, 0, FRAME_WIDTH, FRAME_HEIGHT).data;

    if (!previousFrameRef.current) {
      previousFrameRef.current = new Uint8ClampedArray(current);
      return 0;
    }

    let diff = 0;
    let count = 0;
    for (let index = 0; index < current.length; index += 16) {
      diff += Math.abs(current[index] - previousFrameRef.current[index]);
      count += 1;
    }

    previousFrameRef.current = new Uint8ClampedArray(current);
    if (count === 0) {
      return 0;
    }

    return diff / (count * 255);
  }, []);

  const analyzeFrame = useCallback(async () => {
    if (!runningRef.current || sampleBusyRef.current) {
      return;
    }

    const video = videoRef.current;
    const analyser = analyserRef.current;
    if (!video || !analyser || video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) {
      return;
    }

    sampleBusyRef.current = true;

    try {
      const bytes = new Uint8Array(analyser.frequencyBinCount);
      analyser.getByteTimeDomainData(bytes);

      let energy = 0;
      for (const value of bytes) {
        const centered = (value - 128) / 128;
        energy += centered * centered;
      }
      const rms = Math.sqrt(energy / bytes.length);
      const speaking = rms > 0.045;
      const highVolume = rms > 0.11;
      const motion = measureMotion(video);

      let faceDetected = false;
      let centeredFace = false;
      if (faceDetectorRef.current) {
        try {
          const faces = await faceDetectorRef.current.detect(video);
          faceDetected = faces.length > 0;
          if (faceDetected) {
            const box = faces[0].boundingBox;
            if (box && video.videoWidth > 0) {
              const faceCenter = box.x + box.width / 2;
              const normalizedOffset = Math.abs(faceCenter - video.videoWidth / 2) / video.videoWidth;
              centeredFace = normalizedOffset < 0.18;
            } else {
              centeredFace = true;
            }
          }
        } catch {
          // If detection fails on a frame, keep analysis running.
        }
      }

      const counters = countersRef.current;
      counters.sampleCount += 1;
      counters.volumeTotal += rms;
      counters.motionTotal += motion;
      if (speaking) {
        counters.speakingSamples += 1;
      }
      if (highVolume) {
        counters.highVolumeSamples += 1;
      }
      if (faceDetectorRef.current) {
        counters.faceChecks += 1;
        if (faceDetected) {
          counters.faceDetectedSamples += 1;
        }
        if (centeredFace) {
          counters.centeredFaceSamples += 1;
        }
      }

      setMetrics(calculateMetrics(counters, getElapsedSeconds(), faceDetectionAvailable));
    } finally {
      sampleBusyRef.current = false;
    }
  }, [faceDetectionAvailable, getElapsedSeconds, measureMotion]);

  const stopExperience = useCallback(async () => {
    runningRef.current = false;
    setRunning(false);
    clearTimers();

    if (streamRef.current) {
      for (const track of streamRef.current.getTracks()) {
        track.stop();
      }
      streamRef.current = null;
    }

    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }

    if (audioContextRef.current) {
      await audioContextRef.current.close().catch(() => undefined);
      audioContextRef.current = null;
    }

    analyserRef.current = null;
    faceDetectorRef.current = null;
    sampleBusyRef.current = false;
  }, [clearTimers]);

  const startExperience = useCallback(async () => {
    setErrorMessage("");
    resetCounters();

    if (!navigator.mediaDevices?.getUserMedia) {
      setErrorMessage("This browser does not support camera/microphone capture.");
      return;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { width: { ideal: 960 }, height: { ideal: 540 }, facingMode: "user" },
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        },
      });

      streamRef.current = stream;

      const video = videoRef.current;
      if (!video) {
        throw new Error("Video element not ready.");
      }

      video.srcObject = stream;
      await video.play();

      const audioContext = new AudioContext();
      const source = audioContext.createMediaStreamSource(stream);
      const analyser = audioContext.createAnalyser();
      analyser.fftSize = 2048;
      source.connect(analyser);
      audioContextRef.current = audioContext;
      analyserRef.current = analyser;

      const FaceDetectorCtor = (window as WindowWithFaceDetector).FaceDetector;
      if (FaceDetectorCtor) {
        try {
          faceDetectorRef.current = new FaceDetectorCtor({ fastMode: true, maxDetectedFaces: 1 });
          setFaceDetectionAvailable(true);
        } catch {
          faceDetectorRef.current = null;
          setFaceDetectionAvailable(false);
        }
      } else {
        setFaceDetectionAvailable(false);
      }

      startTimeRef.current = Date.now();
      runningRef.current = true;
      setRunning(true);

      analysisTimerRef.current = window.setInterval(() => {
        void analyzeFrame();
      }, 450);
      elapsedTimerRef.current = window.setInterval(() => {
        setMetrics((current) => ({
          ...current,
          elapsedSeconds: getElapsedSeconds(),
        }));
      }, 1000);
    } catch (error) {
      await stopExperience();
      setErrorMessage(error instanceof Error ? error.message : "Unable to start live coaching.");
    }
  }, [analyzeFrame, getElapsedSeconds, resetCounters, stopExperience]);

  useEffect(() => {
    return () => {
      void stopExperience();
    };
  }, [stopExperience]);

  return (
    <div className="space-y-5">
      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-zinc-900">Live camera + voice coaching (experimental)</h2>
        <p className="mt-2 text-sm text-zinc-600">
          This mode runs on-device signal analysis for body-language presence and voice pacing. No video or audio is
          uploaded by this component.
        </p>

        <div className="mt-4 flex flex-wrap gap-3">
          {running ? (
            <button
              type="button"
              onClick={() => void stopExperience()}
              className="rounded-xl border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
            >
              Stop analysis
            </button>
          ) : (
            <button
              type="button"
              onClick={() => void startExperience()}
              className="rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
            >
              Start camera + mic
            </button>
          )}
          <p className="self-center text-xs text-zinc-500">
            {faceDetectionAvailable
              ? "Face detection enabled"
              : "Face detection unavailable in this browser (voice + movement still active)."}
          </p>
        </div>

        {errorMessage ? <p className="mt-3 text-sm text-red-600">{errorMessage}</p> : null}
      </section>

      <section className="grid gap-5 lg:grid-cols-[1.1fr_1fr]">
        <article className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h3 className="text-sm font-semibold uppercase tracking-wide text-zinc-500">Live preview</h3>
          <div className="mt-3 overflow-hidden rounded-xl border border-zinc-200 bg-zinc-900">
            <video ref={videoRef} muted playsInline className="h-[280px] w-full object-cover" />
          </div>
          <p className="mt-2 text-xs text-zinc-500">
            Session length: <span className="font-medium">{metrics.elapsedSeconds}s</span>
          </p>
        </article>

        <article className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h3 className="text-sm font-semibold uppercase tracking-wide text-zinc-500">Multimodal metrics</h3>
          <div className="mt-3 grid grid-cols-2 gap-3 text-sm">
            <div className="rounded-xl border border-zinc-200 p-3">
              <p className="text-xs text-zinc-500">Speech activity</p>
              <p className="text-lg font-semibold text-zinc-900">{Math.round(metrics.speakingRatio * 100)}%</p>
            </div>
            <div className="rounded-xl border border-zinc-200 p-3">
              <p className="text-xs text-zinc-500">Avg voice energy</p>
              <p className="text-lg font-semibold text-zinc-900">{metrics.avgVolume.toFixed(2)}</p>
            </div>
            <div className="rounded-xl border border-zinc-200 p-3">
              <p className="text-xs text-zinc-500">High volume moments</p>
              <p className="text-lg font-semibold text-zinc-900">{Math.round(metrics.highVolumeRatio * 100)}%</p>
            </div>
            <div className="rounded-xl border border-zinc-200 p-3">
              <p className="text-xs text-zinc-500">Motion/fidget score</p>
              <p className="text-lg font-semibold text-zinc-900">{metrics.motionScore.toFixed(2)}</p>
            </div>
            <div className="rounded-xl border border-zinc-200 p-3">
              <p className="text-xs text-zinc-500">Face in frame</p>
              <p className="text-lg font-semibold text-zinc-900">
                {metrics.facePresenceRatio === null ? "N/A" : `${Math.round(metrics.facePresenceRatio * 100)}%`}
              </p>
            </div>
            <div className="rounded-xl border border-zinc-200 p-3">
              <p className="text-xs text-zinc-500">Centered presence</p>
              <p className="text-lg font-semibold text-zinc-900">
                {metrics.centeredFaceRatio === null ? "N/A" : `${Math.round(metrics.centeredFaceRatio * 100)}%`}
              </p>
            </div>
          </div>
        </article>
      </section>

      <section className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
        <h3 className="text-sm font-semibold uppercase tracking-wide text-zinc-500">Live coaching cues</h3>
        <ul className="mt-3 list-disc space-y-2 pl-5 text-sm text-zinc-700">
          {insights.map((tip) => (
            <li key={tip}>{tip}</li>
          ))}
        </ul>
      </section>
    </div>
  );
}
