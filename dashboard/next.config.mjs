/** @type {import('next').NextConfig} */
const nextConfig = {
  output: "export", // static site → Firebase Hosting (dashboard/out)
  images: { unoptimized: true },
};
export default nextConfig;
